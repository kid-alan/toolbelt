# Tail the Time Machine logs
log stream --predicate 'subsystem == "com.apple.TimeMachine"' --info

# Sho logs for the last hour
log show --predicate 'process == "myprogram"' --last 1h --info --debug


# An unparalleled resourse to undersand how Time Machine works
https://eclecticlight.co/2019/12/03/time-machine-1-how-it-works-or-fails-to/
