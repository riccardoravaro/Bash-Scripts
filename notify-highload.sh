#!/bin/bash

#Generates notification when CPU load average is above specified limit

if [ ! -f ~/.highload.cfg ] #If file doesnt exist, then create it
then
    
    #Redirecting STDOUT to file
    exec 4<&1
    exec 1> ~/.highload.cfg

    #Default Settings
    echo "AUDIO=NO #Sets audio notification"
    echo "GRAPHICAL=NO #Sets notify-send/desktop notification"
    echo "VERBOSE=NO #Sets terminal output"
    echo "CPU_LOAD_TIME=1 #Set time duration for which to check load averages. Later set to argument number. Initial 1, 5 or 15"
    echo "CPU_LOAD_LMT=90 #Set limit for high load average. Any number >0"
    echo "TIME_GAP_NOTIFICATIONS=5 #Set gap between successive notifications. Any number >=0"
    echo "TIME_GAP_BOOT=30 #Set initial delay in starting. Any number >=0"
    echo "TIME_PERIOD=5 #Sets timegap between successive runs"
    echo "#The next few settings are distro dependent. Please edit depending on your configuration."
    echo 'ICON="/usr/share/icons/default.kde4/128x128/devices/cpu.png" #Set the icon to be used for desktop notifications'
    echo 'NOTIFICATION_SOUND="/usr/share/sounds/ubuntu/stereo/system-ready.ogg" #Set the audio file to be used for notifications'
    echo 'PLAYER="paplay" #Set to default player. Usually, paplay'

    #Setting STDOUT back
    exec 1<&4
   
    echo "Creating configuration file with defaults" 

fi

if [ ! -x ~/.highload.cfg ] #If file is not executable, then make it
then 
    chmod +x ~/.highload.cfg
fi

. ~/.highload.cfg #Load configuration file
    
if [ $VERBOSE == "YES" ]
then 
	echo "Loading configuration file"
fi

    
#set -- `getopts agvc:l:t:i: "$@"` #Parse command line parameters and options
#while [ -n "$1" ] #Set settings to passed parameters

while getopts :agvt:l:n:b:p: opt
do
    case "$opt" in
	a) AUDIO=YES;;
	g) GRAPHICAL=YES;;
	v) VERBOSE=YES;;
	t) #case $OPTARG in
	   # 1) CPU_LOAD_TIME=1;; #Set by default
	   # 5) CPU_LOAD_TIME=2;;
	   # 15)CPU_LOAD_TIME=3;;
	   # esac;;
	    CPU_LOAD_TIME=$OPTARG;; #Check performed later
	    #shift ;;
        l) if [ $OPTARG -gt 0 ] 
	   then
	       CPU_LOAD_LMT="$OPTARG"
	   fi;;
	    #shift ;;
	n) if [ $OPTARG -ge 0 ] 
	   then 
	       TIME_GAP_NOTIFICATIONS="$OPTARG"
	   fi;;
	    #shift ;;
	b) if [ $OPTARG -ge 0 ] 
	   then 
	       TIME_GAP_BOOT="$OPTARG"
	   fi;;
	    #shift ;;
	p) if [ $OPTARG -ge 0 ]
	   then 
	       TIME_PERIOD="$OPTARG"
	   fi;;
	*) ;;
	esac
done


if [ "YES" == $VERBOSE ] #Displaying settings
then 
    echo "Parameters set:"
    echo "Audio : $AUDIO"
    echo "Graphical : $GRAPHICAL"
    echo "Verbose : $VERBOSE"
    echo "Load Average Used : $CPU_LOAD_TIME"
    echo "Limit for high load : $CPU_LOAD_LMT"
    echo "Initial time delay : $TIME_GAP_BOOT"
    echo "Gap between successive notifications : $TIME_GAP_NOTIFICATIONS"
    echo ""
fi

##Testing
echo "Done"
#exit 0
##

sleep $TIME_GAP_BOOT #To allow boot process to complete. CPU load will be high initially.

while true
do
    list=`cat /proc/loadavg`
    set -- $list
    
    #load=$CPU_LOAD_TIME #Extract required cpu load
    case $CPU_LOAD_TIME in #To access the arguments. Defaults to 1 minute load average
	5) load=$2;;
	15)load=$3;;
	*) load=$1;;
    esac #http://unix.stackexchange.com/a/93242/29295
    
    load=`echo "scale=2; $load * 100" | bc` #Convert to integer
    load=`printf "%.0f" $load` #Remove decimal digits

    highload=$((`nproc`*$CPU_LOAD_LMT)) #Calculate high load threshold based on number of cores
    
    if test $load -ge $highload
    then
	
	if [ "YES" == $AUDIO ] 
	then
	    $PLAYER $NOTIFICATION_SOUND &
	fi

	#Generates visual notification
	if [ "YES" == $GRAPHICAL ]
	then
	    notify-send -i $ICON "High CPU Load"'!' "The CPU has been hard at work in the past minute." 
	    #No support for timeouts. Default is 5 seconds.
	    #notify-send bug report https://bugs.launchpad.net/ubuntu/+source/notify-osd/+bug/390508
	fi		
	
	#PC Speaker is disabled on default configuration of Ubuntu
	#printf "\a" 
	
	if [ "YES" == $VERBOSE ]
	then
	    echo "CPU load high on `date "+%D at %T"`"!
	fi

	sleep $TIME_GAP_NOTIFICATIONS #High load averages are reflected for the next few seconds 

    fi

    sleep $TIME_PERIOD
done
