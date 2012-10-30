Linfo
=====

Linfo is a light weight portable set of bash scripts to generate statistics for Linux systems.  Each script can be used independently from each other or download the whole set of scripts.

Install
=====

Individual script - Copy and paste the code from a particular script into new file, save, make executable (chmod +x filename) and begin using. 

Whole set - Download the package from the download page on Github.  Extract to directory of choice, change into directory and make scripts executable:

chmod +x *.sh

Alternatively, each script may be placed in /bin or /sbin so it can be called via:  pidinfo 499

Usage
=====

Apache Stats (apstat.sh):  ./apstat.sh
Pidinfo (pidinfo.sh):  ./pidinfo.sh 599
Sysinfo (sysinfo.sh):  ./sysinfo.sh
