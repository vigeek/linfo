#!/bin/bash
## Sysinfo - Linux statistics generation for systems.
## Author - Russ Thompson - russ@viGeek.net
## Tested:  Debian, Ubuntu, CentOS, RHEL, Fedora
## GPL v3

LOG_FILE="/var/log/sysinfo.log"

# No need to edit anything below this line.

func_log() {
 echo -e "$1"
}

func_failure() {
	ERROR="Error:  $1"
exit 1
}

func_echo() {
	echo -e '\e[30;47m'"\033m$1\033[0m"
}

# Official Name
func_echo "Sysinfo -[Host: $(hostname -s)]-"

# Kernel
echo -e "Kernel:  $(cat /proc/version | awk '{print $3}')"

#Uptime
echo -e "Uptime : $(cat /proc/uptime | awk '{ S += $1 } END {printf "%d:%d:%d",S/(60*60),S%(60*60)/60,S%60}') h:m:s"

# Gcc version
echo -e "GCC:  $(gcc --version | head -n 1)"

# Load averages
echo -e "Load Averages:" "$(uptime | awk '{print $10,$11,$12}' | sed 's/,/ /g')"

func_echo "Security Details"

# Generate login failures (dist specific).

if [ -r /var/log/secure ] ; then
   echo -e "Failed Auths: $(cat /var/log/secure | grep -i 'authentication failure' | wc -l) [since] $(cat /var/log/secure | tail -n 1 | awk '{print $1,$2,$3}')"
elif [ -f "/var/log/auth.log" ] ; then
   echo -e "Failed Auths: $(cat /var/log/auth.log | grep -i 'authentication failure' | wc -l) [since] $(cat /var/log/secure | tail -n 1 | awk '{print $1,$2,$3}')"
else
   echo -n ""
fi

func_echo "CPU Statistics"

echo "$(top -b -n 1 |grep ^Cpu | awk '{print "User: " $2 "\nSystem: " $3 "\nIdle: " $5}' | sed -e 's/us,//g' -e 's/sy,//g' -e 's/id,//g')"

func_echo "Memory Statistics"
  echo "Total Memory: $(free -m | grep 'Mem:' | awk '{print $2}') Mb"
  echo "Free Memory: $(free -m | grep 'Mem:' | awk '{print $4}') Mb"
  echo "Used Memory: $(free -m | grep 'Mem:' | awk '{print $3}') Mb"
  echo "Cached Memory: $(free -m | grep 'Mem:' | awk '{print $7}') Mb"

func_echo "Network Statistics"

# ActiveConnections
  echo "Connections in SYN state:" "$(netstat -ant | awk '{print $6}' | grep SYN | wc -l)"
  echo "Connections in LISTEN state:" "$(netstat -ant | awk '{print $6}' | grep LISTEN | wc -l)"
  echo "Connections in ESTABLISHED state:" "$(netstat -ant | awk '{print $6}' | grep ESTABLISHED | wc -l)"

# Socket networking etc.
if [ -f "/proc/net/sockstat" ] ; then
  echo "Active TCP Connections: $(cat /proc/net/sockstat | grep TCP: | awk '{print $3}')"
  echo "Active UDP Connections: $(cat /proc/net/sockstat | grep UDP: | awk '{print $3}')"
fi

# Recieved Bandwidth

#cut -d ":" -f2

if [ -f "/proc/net/dev" ] ; then
	SUM="0"
	for i in `cat /proc/net/dev | grep -e eth | cut -d":" -f2 | awk '{print $1}'` ; do
		SUM="$(echo $SUM + $i | bc)"
	done
	echo "Recieved Bandwidth:  $(echo $SUM | awk '{ s += $1 } END { print s/1024/1024, "Mb"}')"

	# Recieved Packets
	SUM="0"
	for i in `cat /proc/net/dev | grep -e eth | cut -d":" -f2 | awk '{print $2}'` ; do
		SUM="$(echo $SUM + $i | bc)"
	done
	echo "Recieved Packets:  $(echo $SUM)"

	# Recieve Errors
	SUM="0"
	for i in `cat /proc/net/dev | grep -e eth | cut -d":" -f2 | awk '{print $3}'` ; do
		SUM="$(echo $SUM + $i | bc)"
	done
	echo "Recieved Errors:  $(echo $SUM)"

	# Sent Bandwidth
	SUM="0"
	for i in `cat /proc/net/dev | grep -e eth | cut -d":" -f2 | awk '{print $9}'` ; do
		SUM="$(echo $SUM + $i | bc)"
	done
	echo "Sent Bandwidth:  $(echo $SUM | awk '{ s += $1 } END { print s/1024/1024, "Mb"}')"

	# Sent Packets
	SUM="0"
	for i in `cat /proc/net/dev | grep -e eth | cut -d":" -f2 | awk '{print $10}'` ; do
		SUM="$(echo $SUM + $i | bc)"
	done
	echo "Sent Packets:  $(echo $SUM)"

	# Send Errors
	SUM="0"
	for i in `cat /proc/net/dev | grep -e eth | cut -d":" -f2 | awk '{print $11}'` ; do
		SUM="$(echo $SUM + $i | bc)"
	done
	echo "Send Errors:  $(echo $SUM)"
fi

#func_echo "IO Statistics"

for ios in `cat /proc/diskstats |  awk '{$1="" ; $2="" ; print}' | egrep '[shxv]d[a-z][^1-9]' | awk '{print $1}'` ; do

func_echo "IO Statistics - $ios"

  echo -e "Reads Complted: $(cat /proc/diskstats | grep $ios | egrep '[shxv]d[a-z][^1-9]' | awk '{print $4}')"

  echo -e "Time Reading: $(cat /proc/diskstats | grep $ios | egrep '[shxv]d[a-z][^1-9]' | awk '{print $7}' | awk '{ s += $1 } END { print s/1000}') [seconds]"

  echo -e "Writes Completed: $(cat /proc/diskstats | grep $ios | egrep '[shxv]d[a-z][^1-9]' | awk '{print $8}')"

  echo -e "Time Writing: $(cat /proc/diskstats | grep $ios | egrep '[shxv]d[a-z][^1-9]' | awk '{print $11}' | awk '{ s += $1 } END { print s/1000}') [seconds]"

  echo -e "Current IO Requests: $(cat /proc/diskstats | grep $ios | egrep '[shxv]d[a-z][^1-9]' | awk '{print $12}')"

  echo -e "Time doing IO: $(cat /proc/diskstats | grep $ios | grep '[shxv]d[a-z][^1-9]' | awk '{print $13}') ms"

done


