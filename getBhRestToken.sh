#!/bin/bash
#Function:  	This script, getBhRestToken.sh, generates and gives back a new BhRestToken everytime it is run.
#           	This script is used within the script getDataAndLoadToStorage.sh. You can use this
#           	script also to generate a BhRestToken to use it in Postman for your manual tests. In that case run this script
#           	by typing ./getBhRestToken.sh in the command line.
#Arguments: 	-
#Author:    	semiha.dogan@student.kdg.be
#Requires:  	valid Bullhorn user credentials.  

#--------------------------- Variables ---------------------------#
client_id="f76807fa-a2b6-469d-a85c-9a100215ddca"
client_secret="PL2Zvkd9MI43CP9vuZooBKDj"
redirect_uri="https://app.bullhornstaffing.com"

#--------------------------- Functions ---------------------------#

function getAuthorizationCode(){
    	url="https://auth.bullhornstaffing.com/oauth/authorize?client_id=${client_id}&response_type=code&action=Login&redirect_uri=${redirect_uri}"
    	uname=`echo "TWFydHluYVNrbG9kb3dza2EK" | base64 -d`
    	pw=`echo "TWFhcnQwMzIwMjEK" | base64 -d`

    	wget --output-file "outputfile" -O bullhorn_web_page --post-data="username=${uname}&password=${pw}" "$url"


    	authorization_code=`cat outputfile | grep -o 'code=22.*&' | grep -o "22.*[^&]" | uniq | sed 's/%3A/\:/g'`
    	rm outputfile bullhorn_web_page > /dev/null
    	echo ${authorization_code}

}


function generateInitialRefreshAndAccessToken(){
    	authorization_code=$1
    	curl -s \
    	--request POST \
    	--data "grant_type=authorization_code&code=${authorization_code}&client_id=${client_id}&client_secret=${client_secret}&redirect_uri=${redirect_uri}" \
    	https://auth.bullhornstaffing.com/oauth/token > refresh_and_access_token.txt
}

#!/bin/bash
#Function:  	This script, getBhRestToken.sh, generates and gives back a new BhRestToken everytime it is run.
#           	This script is used within the script getDataAndLoadToStorage.sh. You can use this
#           	script also to generate a BhRestToken to use it in Postman for your manual tests. In that case run this script
#           	by typing ./getBhRestToken.sh in the command line.
#Arguments: 	-
#Author:    	semiha.dogan@student.kdg.be
#Requires:  	valid Bullhorn user credentials.  

#--------------------------- Variables ---------------------------#
client_id="f76807fa-a2b6-469d-a85c-9a100215ddca"
client_secret="PL2Zvkd9MI43CP9vuZooBKDj"
redirect_uri="https://app.bullhornstaffing.com"

#--------------------------- Functions ---------------------------#

function getAuthorizationCode(){
    	url="https://auth.bullhornstaffing.com/oauth/authorize?client_id=${client_id}&response_type=code&action=Login&redirect_uri=${redirect_uri}"
    	uname=`echo "TWFydHluYVNrbG9kb3dza2EK" | base64 -d`
    	pw=`echo "TWFhcnQwMzIwMjEK" | base64 -d`

    	wget --output-file "outputfile" -O bullhorn_web_page --post-data="username=${uname}&password=${pw}" "$url"


    	authorization_code=`cat outputfile | grep -o 'code=22.*&' | grep -o "22.*[^&]" | uniq | sed 's/%3A/\:/g'`
    	rm outputfile bullhorn_web_page > /dev/null
    	echo ${authorization_code}

}


function generateInitialRefreshAndAccessToken(){
    	authorization_code=$1
    	curl -s \
    	--request POST \
    	--data "grant_type=authorization_code&code=${authorization_code}&client_id=${client_id}&client_secret=${client_secret}&redirect_uri=${redirect_uri}" \
    	https://auth.bullhornstaffing.com/oauth/token > refresh_and_access_token.txt
}


function generateRefreshAndAccessToken(){
    	refresh_token=$1
    	curl -s \
    	--request POST \
    	--data "grant_type=refresh_token&refresh_token=${refresh_token}&client_id=${client_id}&client_secret=${client_secret}" \
    	https://auth.bullhornstaffing.com/oauth/token > refresh_and_access_token.txt
}


function getRefreshToken() {
    	refresh_token=`cat refresh_and_access_token.txt | grep "refresh_token" | grep -o "\"22:.*\"" | tr -d \"`
    	echo ${refresh_token}
}


function getAccessToken() {
    	access_token=`cat refresh_and_access_token.txt | grep "access_token" | grep -o "\"22:.*\"" | tr -d \"`
    	echo ${access_token}
}


function getBhRestToken() {
    	access_token=$1
    	curl -s \
    	--request POST \
    	--data "version=*&access_token=${access_token}" \
    	https://rest.bullhornstaffing.com/rest-services/login > BhRestToken.txt
    	BhRestToken=`cat BhRestToken.txt | grep "BhRestToken" | cut -d "\"" -f 4`
    	echo ${BhRestToken}
}


#--------------------------- Main ---------------------------#

function main() {

touch refresh_and_access_token.txt

do_while=0
while [ -z ${BhRestToken} ] || [ ${do_while} -eq 0 ]
do
    	do_while=1

    	refresh_token=`getRefreshToken`
    	generateRefreshAndAccessToken ${refresh_token}
    	access_token=`getAccessToken`
    	BhRestToken=`getBhRestToken ${access_token}`

    	while [ "`grep -o "error" refresh_and_access_token.txt`" = "error" ] || [ ! -s refresh_and_access_token.txt ] > /dev/null
    	do
            	authorization_code=`getAuthorizationCode`
            	generateInitialRefreshAndAccessToken ${authorization_code}
    	done
    	echo ${BhRestToken}

done

}

main
