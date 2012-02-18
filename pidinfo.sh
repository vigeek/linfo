#!/bin/bash
## piDinfo - Linux statistics generation for individual processes.
## Author - Russ Thompson - russ@viGeek.net
## Tested:  Debian, Ubuntu, CentOS, RHEL, Fedora
## GPL v3

LOG_FILE="/var/log/pidinfo.log"

# No need to edit anything below this line.

usage() {
cat << EOF
Usage: $0 [OPTION]... [PID]...
pidinfo - Obtain statistics for an individual process.

Example:
pidinfo -f output.txt 2128

RUN OPTIONS:
-h, Shows usage parameters.
-p, Obtains statistics from the parent PID (if applicable).

Suggestions, questions? Russ@vigeek.net

$ERROR
EOF
exit 1
}

PID_VAR="${!#}"

while getopts "hf:pv" opts
do
case $opts in
    h)
        usage
        exit 1
        ;;
    p)
        P_PID="1"
        ;;
    v)
        # Enable verbose methods
        VERBOSE=true
        ;;
    ?)
      usage
      exit 1
        ;;
esac
done



# Determine if we have a numeric variable.
echo $PID_VAR | grep "[^0-9]" > /dev/null
	if [ $? -eq "0" ] ; then
		PID_VAR=`pidof $1`
	fi
	
func_log() {
 echo -e "$1"
}

func_failure() {
	ERROR="Error:  $1"
	usage 
exit 1
}

func_echo() {
	echo -e '\e[30;47m'"\033m$1\033[0m"
}

if [ -z "$PID_VAR" ] ; then
	func_failure "No pid or process name provided"
fi
# Ensure pid exists
kill -0 $PID_VAR 2> /dev/null
	if [ $? -eq "1" ] ; then
		func_failure "PID is not active"
	fi

# Official Name
func_echo "Pidinfo -[PID: $PID_VAR]-"

# Thread and Status
echo "$(cat /proc/$PID_VAR/status | grep -e Name: -e State)"

# Binary location
if [ -f "/proc/$PID_VAR/exe" ] ; then
	echo "Executor: $(ls -l /proc/$PID_VAR/exe | awk '{print $10,$11}' | sed "s/->//g")"
fi

# Startup command
if [ -f "/proc/$PID_VAR/cmdline" ] ; then
	echo "Startup Command:  $(cat /proc/$PID_VAR/cmdline)"
fi

# Who's running the process.
UID_VAR=`cat /proc/$PID_VAR/status | grep 'Uid' | awk '{print $2}'`
GID_VAR=`cat /proc/$PID_VAR/status | grep 'Gid' | awk '{print $2}'`
UID_WHO=`cat /etc/passwd | grep $UID_VAR | awk -F":" '{print $1}' | head -n 1`
	if [ -z $UID_WHO ] ; then
		UID_WHO="$UID_VAR"
	fi
GID_WHO=`cat /etc/passwd | grep $GID_VAR | awk -F":" '{print $1}' | head -n 1`
   if [ -z $GID_WHO ] ; then
		GID_WHO="$GID_VAR"
   fi

echo "Running as user:  $UID_WHO"
echo "Running as group:  $GID_WHO"

# Startup time
echo "Started on:  $(ls -ld /proc/$PID_VAR | awk '{print $6,$7,$8}' | cut -d"/" -f1)"

# Process Priority
echo "Priority (nice): $(cat /proc/$PID_VAR/stat | awk '{print $19}')"

func_echo "Resource Statistics"

echo "$(cat /proc/$PID_VAR/status | grep Threads)"

# Process Usage
SUM="0"
for i in `ps -eo %cpu,pid|sort -k2 -r | grep $PID_VAR | awk '{print $1}'` ; do
	SUM="$(echo $SUM + $i | bc)"
done
echo "CPU Usage:  $SUM%"

# Generate Memory Usage and translate to Megabytes
echo "Memory Usage: $(cat /proc/$PID_VAR/status | grep 'VmSize' | awk '{print $2}' |  \
awk '{ s += $1 } END { print s/1024, "Mb"}')"

echo "Maximum Memory Used:  $(grep VmPeak /proc/$PID_VAR/status | awk '{print $2}'  |  \
awk '{ s += $1 } END { print s/1024, "Mb"}')"

# Active connections
echo "Active connections: $(netstat -np | grep $PID_VAR | wc -l)"

func_echo "IO Statistics"

if [ -f "/proc/$PID_VAR/io" ] ; then
	# RW Statistics
	echo "Read (Syscalls) Bytes: $(cat /proc/$PID_VAR/io | grep 'rchar' | awk '{ s += $2 } END { print s/1024/1024, "Mb"}')"
	echo "Write (Syscalls) Bytes: $(cat /proc/$PID_VAR/io | grep 'wchar' | awk '{ s += $2 } END { print s/1024/1024, "Mb"}')"
	
	# IO Statistics
	echo "IO (Disk) Read Bytes: $(cat /proc/$PID_VAR/io | grep 'read_bytes' | awk '{ s += $2 } END { print s/1024/1024, "Mb"}')"
	echo "IO (Disk) Write Bytes: $(cat /proc/$PID_VAR/io | grep 'write_bytes' | awk '{ s += $2 } END { print s/1024/1024, "Mb"}')"
	
	# Calls performed
	echo "Syscalls (Read): $(cat /proc/$PID_VAR/io | grep 'syscr' | awk '{print $2}') "
	echo "Syscalls (Write): $(cat /proc/$PID_VAR/io | grep 'syscw' | awk '{print $2}') "
fi

func_echo "Open file descriptors: "
	# Open file descripters
	echo "$(ls -l /proc/$PID_VAR/fd/ | awk '{print $10,$11}' | grep "/" | sed "s/->//g" )"

