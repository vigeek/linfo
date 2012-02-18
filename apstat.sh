#!/bin/bash
# Apache Statistics - Russ@vigeek.net
# Generates apache statistics from the command line.

func_echo() {
	echo -e '\e[30;47m'"\033m$1\033[0m"
}

# Get parent pid.
# Parent pid can also be obtained through /proc/pid/status
PARENT_PID=`ps -eo ppid,cmd,user | grep 'apache' | grep -v "grep" | head -n 1 | awk '{print $1}'`

# Process priority (Parent)
PID_PRIORITY=`cat /proc/$PARENT_PID/stat | awk '{print $19}'`

# Determine when it started.
START_TIME=`ls -ld /proc/$PARENT_PID | awk '{print $6,$7,$8}' | cut -d"/" -f1`

# Number of open files
OPEN_FILES=`lsof | grep httpd | wc -l`

# Generate CPU utilization

SUM="0"
for i in `ps -eo %cpu,pid,cmd|sort -k2 -r | grep 'httpd' | grep -v "grep" | awk '{print $1}'` ; do
	SUM="$(echo $SUM + $i | bc)"
done

# Generate memory utilization.
MEMORY_USAGE=`ps aux | grep httpd | grep -v "grep" | awk '{ s += $6 } END { print s/1024, "Mb"}'`

# Threads (Childs) - Total including parent.
NO_THREADS=`ps -ef | grep httpd | grep -v "grep" | wc -l`

# Connections total
CONN_TOTAL=`netstat -ap | grep httpd | wc -l`

# Connections in SYN
SYN_STATE=`netstat -ap | grep httpd | grep 'SYN' | wc -l`

# Connections in TimeWAIT
WAIT_STATE=`netstat -ap | grep httpd | grep 'TIME_WAIT' | wc -l`

# Connections in LISTEN
LISTEN_STATE=`netstat -ap | grep httpd | grep 'LISTEN' | wc -l`

# Connections in ESTABLISHED/CONNECTED
ESTB_STATE=`netstat -ap | grep httpd | grep -e 'ESTABLISHED' -e 'CONNECTED' | wc -l`

# Highest connection count per IP
CONN_COUNT_IP=`netstat -tp | grep http | awk '{print $4}' | awk -F':' '{print $4}' |  grep ^[0-9] | uniq -c | sort -rn | head -n 10`


# Generate IO statistics.
READ_SUM="0" ; WRITE_SUM="0" ; READ_BSUM="0" ; WRITE_BSUM="0"

for i in `pidof httpd | awk -F " " '{print}'` ; do 
	READ_COUNT=`cat /proc/$i/io | grep 'rchar' | awk '{print $2}'`
	WRITE_COUNT=`cat /proc/$i/io | grep 'wchar' | awk '{print $2}'`
	READ_BCOUNT=`cat /proc/$i/io | grep 'read_bytes' | awk '{print $2}'`
	WRITE_BCOUNT=`cat /proc/$i/io | grep -v "cancelled_" | grep 'write_bytes' | awk '{print $2}'`
	
	READ_SUM="$(echo $READ_SUM + $READ_COUNT | bc)"
	WRITE_SUM="$(echo $WRITE_SUM + $WRITE_COUNT | bc)"
	READ_BSUM="$(echo $READ_BSUM + $READ_BCOUNT | bc)"
	WRITE_BSUM="$(echo $WRITE_BSUM + $WRITE_BCOUNT | bc)"
done

func_echo "General Statistics\t"
	echo "Parent Pid:  $PARENT_PID"
	echo "Started:  $START_TIME"
	echo "Priority(Nice):  $PID_PRIORITY"
	echo "Open file count:  $OPEN_FILES"

func_echo "Connectivity\t"
	echo "Total Connections:  $CONN_TOTAL"
	echo "SYN Connections:  $SYN_STATE"
	echo "Wait Connections:  $WAIT_STATE"
	echo "Etsablished Connections:  $ESTB_STATE"
	echo "Listen State:  $LISTEN_STATE"

func_echo "Performance\t"
	echo "Threads:  $NO_THREADS"
	echo "CPU Usage:  $SUM%"
	echo "Memory Usage:  $MEMORY_USAGE"

func_echo "IO Statistics\t"
	echo "Read Count:  $READ_SUM"
	echo "Write Count:  $WRITE_SUM"
	echo "Read Bytes:  $READ_BSUM"
	echo "Write Bytes:  $WRITE_BSUM"

