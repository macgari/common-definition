#!/bin/bash

NCI_USERNAME=$1
NCI_PASSWORD=$2

if [ $# -lt 2 ]; then echo "         Usage:  use NIH authentication                         "
                      echo "         ./nci.download.sh nih-username nih-password            "
   exit
fi

ROOT=$(pwd)
NCI_FILE=$ROOT/nci.zip


UTS_URL=https://cbiit.cancer.gov/evs-download/download/UTSServlet
UMLS_URL=https://cbiit.cancer.gov/evs-download/download/UMLSServlet

curl --request GET --url $UMLS_URL?ticket=$(curl --request POST --url $UTS_URL?username=$NCI_USERNAME&password=$NCI_PASSWORD --header 'Cache-Control: no-cache') --header 'Cache-Control: no-cache' --output $NCI_FILE