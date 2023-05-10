#!/bin/bash
#Function:  	This script, main.sh, runs the scripts getDataAndLoadToStorage.sh and createTables.sh.
#           	This script gets all needed data from Bullhorn and loads this data in Google Storage (getDataAndLoadToStorage.sh)
#           	and creates and inserts data in the first layer of Tables, the dimension tables and fact table in Google Big Query (createTables.sh).
#           	The script is run in a cronjob. Type crontab -e in the command line for cronjob settings.
#Arguments: 	-
#Author:    	semiha.dogan@student.kdg.be
#Requires:  	-


echo "--------------- Begin cronjob `date "+%A %d %b %Y - %H:%M"` ---------------" >> logfile.txt

begin=`date +%s`


./getDataAndLoadToStorage.sh
./createTables.sh


end=`date +%s`
total_time=$((end - begin))
total_min=$((total_time / 60))
total_s=$((total_time % 60))
echo "--------------- End cronjob: total time ${total_min} min ${total_s} s ---------------" >> logfile.txt
