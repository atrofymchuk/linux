
#!/bin/bash

format="%5s %-5s %-5s %s %-5s\n"
printf "$format" PID TTY STAT TIME COMMAND

for proc in `ls /proc/ | egrep "^[0-9]" | sort -n | xargs`
do

    if [[ -f /proc/$proc/status ]]
        then
        PID=$proc

    COMMAND=`cat /proc/$proc/cmdline`
    if  [[ -z "$COMMAND" ]]
        then
        COMMAND="[`awk '/Name/{print $2}' /proc/$proc/status`]"
    else
        COMMAND=`cat /proc/$proc/cmdline`
    fi
    tp=`ls -l /proc/$proc/fd/ | grep -E '\/dev\/tty|pts' | cut -d\/ -f3,4 | uniq`
    TTY=`awk '{ if ($7 == 0) {printf "?"} else { printf "'"$tp"'" }}' /proc/$proc/stat`
    STAT=`cat /proc/$proc/status | awk '/State/{print $2}'`
    TIME=`awk -v ticks="$(getconf CLK_TCK)" '{print strftime ("%M:%S", ($14+$15)/ticks)}' /proc/$proc/stat`
    printf "$format" $PID $TTY $STAT $TIME "$COMMAND"
    fi
done
