#!/bin/sh
# /etc/init.d/firewall: set up the iptables rules
### BEGIN INIT INFO
# Provides:          rc.firewall
# Required-Start:    $networking
# Required-Stop:     $networking
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
### END INIT INFO

firewall_config="/etc/firewall.conf"

check_config() {
if [[ -s "$firewall_config" ]]; then
	return 0
else
	echo "File "$firewall_config" doesn't exist, or empty. All rules are emergency flushed (accept all)"
	accept_all
	return 1
fi
}

accept_all() {
   iptables -F
   iptables -X
   iptables -t nat -F
   iptables -P INPUT ACCEPT
   iptables -P OUTPUT ACCEPT
   iptables -P FORWARD ACCEPT
}

drop_all() {
   iptables -F
   iptables -X
   iptables -t nat -F
   iptables -P INPUT DROP
   iptables -P FORWARD DROP
}


apply_rules() {
if [[ check_config = 0 ]]; then
	iptables-restore < "$firewall_config"
fi
}


case "$1" in
start)
   drop_all
   apply_rules
   echo "IPTABLES FIREWALL START"
   ;;

stop)
   echo "IPTABLES FIREWALL STOP"
   accept_all
   ;;

restart)
   echo "IPTABLES FIREWALL RESTART"
   accept_all
   drop_all
   apply_rules
   ;;

reload)
   echo "IPTABLES FIREWALL RESTART"
   accept_all
   drop_all
   apply_rules
   ;;
   
*)
echo "USAGE: rc.firewall {start|stop|restart}"
esac

