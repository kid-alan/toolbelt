#!/bin/bash
#
# stream-udp.sh
#
# Simplifies UDP streaming of TS files.
#
# Usage:
# stream-udp file.ts targetIP port bitrate
#
#

## Initiating some functions
source /bin/myfunctions.sh
function clean_exit {
	echo ""
	echo "Attempting a clean exit"
	echo "Killing child processes..."
	ps -ef | grep $FIFOFILE | awk '{print $2}' | xargs kill
	echo "Deleting temp files..."
	rm -rf $FIFOFILE
	echo "Done!"
	exit 0
}
function help {
echo "Usage: stream-udp file.ts targetIP port bitrate"
echo "Try -h or --help for full info"
exit 0
}

trap 'clean_exit' INT QUIT TERM HUP

## -h --help
if [ "$1" == "-h" ] | [ "$1" == "--help" ]
  then
	echo "Usage: stream-udp file.ts targetIP port bitrate"
	echo "-"
	echo "About:"
	echo "stream-udp is used to cast TS files via UDP protocol."
	echo -e "It is a bash script, which increases usability of the \nAvalpa OpenCaster tools."
	echo "Send bugs to alan.root@cifratech.com"
	exit 0
fi

## Checks amount of arguments
if [ $# -eq 0 ]
  then
    echo "Error! No arguments supplied"
	help
	exit 0
elif [ $# -lt 4 ]
  then
	echo "Error! Not enough arguments"
	help
	exit 0
fi

## Get command parameters
FILENAME=$1
IP=$2
PORT=$3
BITRATE=$4

## Checks if file exists
if [ ! -f $FILENAME ];
  then
	echo "Error! No such file \"$FILENAME\""
	exit 0
fi

## Checks if IP is correct
if ! valid_ip $IP;
  then
	echo "Error! Check IP format"
	exit 0
fi

## Checks if PORT is correct
if ! [[ $PORT =~ ^[0-9]+$ && $PORT -le 65536 && $PORT -ge 1024 ]]; then
	echo "Error! Port should be numerical in 1024-65536 range"
	exit 0
fi

## Checks if this file is already broadcasting
echo "Checking file..."
BASEFILE=$(basename "$FILENAME" .ts)
CHECKFILE=$(ps aux | awk '/'$BASEFILE'/ && /stream-udp/ && !/awk/' | awk '!/'$IP'/ || !/'$PORT'/' | awk 'NR==1{print $14, $15}')
if [[ -n $CHECKFILE ]];
then
	while true; do
    read -p "Warning! \"$(basename "$FILENAME")\" is already broadcasting to $CHECKFILE You can use this already existing stream. Continue streaming anyway? [y/n]" -r yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) echo "Exiting..."; exit;;
        * ) ;;
    esac
done
fi

## Evaluates bitrate of chosen TS
echo "Trying to evaluate bitrate..."
pcr=( $(timeout 5s  tspcrmeasure $FILENAME 3000000 | awk '{print $(NF)}' | grep -o "[0-9.]*" | cut -f1 -d".") )
C_BITRATE=0
for n in "${pcr[@]}" ; do
    ((n > C_BITRATE)) && C_BITRATE=$n
done


echo "Calculated bitrate of \"$(basename "$FILENAME")\" is around $C_BITRATE bits/s"
## Checks if bitrate is correct
MBS=$(echo "scale=3; $BITRATE/1000000" | bc -l) #Calculates Mb/s
if ! [[ $BITRATE =~ ^[0-9]+$ ]]; then
	echo "Error! Bitrate should be numerical and in bits/sec"
	exit 0
elif [[ $BITRATE -lt $C_BITRATE ]]; then
	while true; do
    read -p "The chosen bitrate (0$MBS Mb/s) is lower then estimated bitrate of file. Are you sure you want to continue? [y/n]" -r yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) echo "Exiting..."; exit;;
        * ) ;;
    esac
done
fi

## Checks if there is an already existing stream
echo "Checking for IP collisions..."
timeout 0.5s tsudpreceive $IP $PORT > /tmp/udpcheck.$$
if [[ -s /tmp/udpcheck.$$ ]]; then
    echo "Warning! There is an already existing stream with this destination in your network."
	echo "Try another destination IP or port"
	rm -rf /tmp/udpcheck.$$
	exit 0
else
	echo "OK!"
	rm -rf /tmp/udpcheck.$$
fi

#The streaming itself
FIFOFILE=/tmp/fifo.$$
mkfifo $FIFOFILE
{
tsloop $FILENAME > $FIFOFILE &
tsudpsend $FIFOFILE $IP $PORT $BITRATE &
} &>/dev/null

echo -e "File:\t $(basename "$FILENAME")"
echo -e "IP:\t $IP $PORT"
echo -e "Bitrate: $MBS Mb/s" 

#Keeps you in program
while true
do
echo -ne "Streaming    \r"
sleep 0.3
echo -ne "Streaming #  \r"
sleep 0.3
echo -ne "Streaming ## \r"
sleep 0.3
echo -ne "Streaming ###\r"
sleep 0.3
echo -ne "Streaming  ##\r"
sleep 0.3
echo -ne "Streaming   #\r"
sleep 0.3
done
