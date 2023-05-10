#!/bin/bash
#Function:  	This script, getBhRestToken.sh, generates and gives back a new BhRestToken everytime it is run.
#           	This script is used within the script getDataAndLoadToStorage.sh. You can use this
#           	script also to generate a BhRestToken to use it in Postman for your manual tests. In that case run this script
#           	by typing ./getBhRestToken.sh in the command line.
#Arguments: 	-
#Author:    	semiha.dogan@student.kdg.be
#Requires:  	valid Bullhorn usedentials.

#--------------------------- General functions ---------------------------#


function writeResultToLogfile() {
    	if [ $? -eq 1 ]
    	then
            	result="NIET "
    	fi
    	echo "De tabel $1 is ${result}gemaakt." >> $2

}
#--------------------------- Create first layer tables with data in storage ---------------------------#


function getEntities() {
    	csv=$1
    	entities=`cat $csv | cut -d ";" -f "1" | sort | uniq`
    	echo $entities
}

csv="entity_field_query.csv"
entities=`getEntities $csv`
dataset="bullhornData"
bucket_name="gs://my-bullhorn-bucket"

for entity in $entities
do
    	/snap/bin/bq load --source_format=NEWLINE_DELIMITED_JSON --replace --autodetect ${dataset}.${entity} ${bucket_name}/${entity}.json
    	writeResultToLogfile ${entity} logfile.txt
done


#--------------------------- Dimensions ---------------------------#


#Delete dimensions
/snap/bin/bq rm -f --table=true factDimensions.Dim_Kandidaat
echo "De dimensie Dim_ Kandidaat is verwijdert." >> logfile.txt

/snap/bin/bq rm -f --table=true factDimensions.Dim_Plaatsing
echo "De dimensie Dim_Plaatsing is verwijdert." >> logfile.txt

/snap/bin/bq rm -f --table=true factDimensions.Dim_Shortlist
echo "De dimensie Dim_Shortlist is verwijdert" >> logfile.txt

/snap/bin/bq rm -f --table=true factDimensions.Dim_Vacature
echo "De dimensie Dim_Vacature verwijdert" >> logfile.txt

#create dimensions with query results
/snap/bin/bq query \
--destination_table factDimensions.Dim_Kandidaat \
--use_legacy_sql=false \
'SELECT id AS dim_kandidaat_id, name AS dim_kandidaat_naam, dateAvailable AS dim_kandidaat_datum_beschikbaar ,
occupation AS dim_kandidaat_gewenste_functie, mobile AS dim_kandidaat_mobiele_telefoon, email AS dim_kandidaat_persoonlijke_email, dayRateLow AS dim_kandidaat_huidig_dagtarief
FROM `bullhorn-350807.bullhornData.Candidate`'

writeResultToLogfile Dim_Kandidaat logfile.txt

/snap/bin/bq query \
--destination_table factDimensions.Dim_Plaatsing \
--use_legacy_sql=false \
'SELECT id AS dim_plaatsing_id, status AS dim_plaatsing_status,
employmentType AS dim_plaatsing_type_dienstverband, dateBegin AS dim_plaatsing_startdatum
FROM `bullhorn-350807.bullhornData.Placement`'

writeResultToLogfile Dim_Plaatsing logfile.txt

/snap/bin/bq query \
--destination_table factDimensions.Dim_Shortlist \
--use_legacy_sql=false \
'SELECT id AS dim_shortlist_id, dateAdded AS dim_shortlist_datum_toegevoegd,
sendingUser.firstName AS dim_shortlist_toegevoegd_door_voornaam,
sendingUser.lastName AS dim_shortlist_toegevoegd_door_achternaam FROM `bullhorn-350807.bullhornData.JobSubmission`'

writeResultToLogfile Dim_Shortlist logfile.txt

/snap/bin/bq query \
--destination_table factDimensions.Dim_Vacature \
--use_legacy_sql=false \
'SELECT id AS dim_vacature_id, title AS dim_vacature_naam, clientCorporation.name AS dim_vacature_bedrijf,
isOpen AS dim_vacature_open_gesloten,branchCode AS dim_vacature_deelbedrijf,
correlatedCustomText10 AS dim_vacature_eindklant FROM `bullhorn-350807.bullhornData.JobOrder`'

writeResultToLogfile Dim_Vacature logfile.txt


#--------------------------- Fact  ---------------------------#


#variables
table_name=factDimensions.Fact_ats
query=`cat /home/googlegen/fact`

#delete fact
bq rm -f --table=true $table_name
echo "Het feit $table_name is verwijdert"


#create fact with query results
bq query \
--destination_table $table_name \
--use_legacy_sql=false \
$query

#write result to logfile
writeResultToLogfile ${table_name} logfile.txt
