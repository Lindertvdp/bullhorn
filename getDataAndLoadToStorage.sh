#!/bin/bash
#Function:  	This script, getDataAndLoadToStorage.sh, gets all needed data from Bullhorn and loads this data in Google Storage.
#           	This script needs a csv file called entity_field_query.csv which contains needed data information.
#           	The script is run in the script main.sh.
#Arguments: 	-
#Author:    	semiha.dogan@student.kdg.be
#Requires:  	gcloud sdk

#install /snap/bin/gsutil

#--------------------------- Variables ---------------------------#


RESTURL="https://rest22.bullhornstaffing.com/rest-services/4yhya1/"
csv="entity_field_query.csv"
bucket_name="gs://my-bullhorn-bucket"
bucket_location="europe-west1"


#--------------------------- Functions ---------------------------#


function getData(){
    	entity=$1
    	fields=$2
    	query=$3
    	BhRestToken=$4
    	start=$5
    	count=$6
    	curl -s "${RESTURL}/\
search/\
${entity}?\
fields=${fields}\
&query=${query}\
&BhRestToken=${BhRestToken}\
&start=${start}\
&count=${count}\
&sort=id" > ${entity}.json
}


function getEntities() {
    	csv=$1
    	entities=`cat $csv | cut -d ";" -f "1" | sort | uniq`
    	echo $entities
}


function getFields() {
    	csv=$1
    	entity=$2
    	fields=`cat $csv | grep "$entity" | cut -d ";" -f "2"| tr "\n" "," | sed 's/,$//g'`
    	echo ${fields}
}


function getQuery() {
    	csv=$1
    	entity=$2
    	query=`cat $csv | grep "$entity" | cut -d ";" -f "3" | sort | uniq`
    	echo ${query}
}


function getTotal() {
    	entity=$1
    	total=`cat ${entity}.json | grep -o "\"total\":[0-9]*" | grep -o [0-9]*`
    	echo $total
}


function getCount() {
    	entity=$1
    	count=`cat ${entity}.json | grep -o "\"count\":[0-9]*" | grep -o [0-9]*`
    	echo $count
}


function calculateNumberOfIterations() {
    	total=$1
    	count=$2
    	quotient=$((total / count))
    	rest=$((total % count))
    	number_of_iterations=$((quotient + 1))

    	if [ $rest -eq 0 ]
    	then
            	number_of_iterations=$quotient
    	fi
    	echo $number_of_iterations
}


function jsonToJsonl() {
    	jsonFile=$1
    	cat ${jsonFile} | sed 's/.*\"data\":[[]//g' | sed 's/}$//g' | sed 's/[]]$//g' | sed "s/},{/}\\n{/g"
}


#getTable: per API call kan je een beperkt aantal lijnen opvragen.
#om een hele tabel te krijgen moeten we dus itereren

function getTable() {
    	entity=$1
    	fields=$2
    	query=$3
    	BhRestToken=$4
    	count=$5
    	number_of_iterations=$6

    	echo "`date "+%H:%M"`: De BhRestToken is ${BhRestToken}" >> logfile.txt
    	echo "De tabel $entity wordt opgehaald uit Bullhorn..." >> logfile.txt
    	echo "Er zijn $number_of_iterations iteraties nodig om de tabel $entity op te halen" >> logfile.txt
   	 
    	for i in $( seq 0 $((number_of_iterations-1)) )
    	do
            	start=$((i*count))
            	echo "   De $((i+1))e reeks data wordt opgehaald..." >> logfile.txt
            	getData $entity $fields $query $BhRestToken $start $count

            	echo " 	$((i+1)) omzetten naar jsonl..." >> logfile.txt
            	jsonToJsonl ${entity}.json >> ${entity}.jsonl
            	echo -e "\r" >> ${entity}.jsonl
    	done

    	rm ${entity}.json
    	mv ${entity}.jsonl ${entity}.json
}


function removeDataFromVm() {
    	for entity in $entities
    	do
            	rm ${entity}.json ${entity}.jsonl 2> /dev/null
    	done
}


function createBucket() {
    	bucket_location=$1
    	bucket_name=$2
    	/snap/bin/gsutil mb -b on -l ${bucket_location} ${bucket_name} 2> /dev/null
}


function uploadFileToBucket() {
    	file_name=$1
    	bucket_name=$2

    	/snap/bin/gsutil cp ~/${file_name} ${bucket_name} > /dev/null

    	if [ $? -eq 1 ]
    	then
            	result="NIET "
    	fi
    	echo " ${file_name} is ${result}opgeladen in Google Storage" >> logfile.txt

}


#--------------------------- Main ---------------------------#


function main() {


createBucket ${bucket_location} ${bucket_name}

entities=`getEntities $csv`

removeDataFromVm

for entity in $entities
do
    	BhRestToken=`./getBhRestToken.sh`
    	fields=`getFields $csv $entity`
    	query=`getQuery $csv $entity`
    	start=0
    	count=500
   	 
    	getData $entity $fields $query $BhRestToken $start $count
  	 
    	total=`getTotal $entity`
    	count=`getCount $entity`
    	number_of_iterations=`calculateNumberOfIterations $total $count`

    	getTable $entity $fields $query $BhRestToken $count $number_of_iterations

    	total_rows=`cat ${entity}.json | wc -l`

    	if [ ${total_rows} -eq ${total} ]
    	then   	 
            	uploadFileToBucket ${entity}.json ${bucket_name}
    	fi

done


}

main
