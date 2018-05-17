#!/bin/sh -f

###############################################################
##### Home for processing umls and nci pipelines          #####
#####  - runs umls, nci, ohdsi, evn pipelines in parallel #####
###############################################################

# update the following parameters

NIH_USER=$nih_username
NIH_PASS=$nih_password

MYSQL_USER=$mysql_username
MYSQL_PASS=$mysql_password

EVN_USERNAME=$evn_username 
EVN_PASSWORD=$evn_password

#needs fresh link twice a year
UMLS_URL=https://download.nlm.nih.gov/umls/kss/2017AB/umls-2017AB-full.zip

#needs to be downloaded manually and saved in a known path
OHDSI_ZIP=ohdsi-vocab.zip

chmod 775 *sh

echo "Processing UMLS..."
sh umls.nlm.sh $NIH_USER $NIH_PASS $UMLS_URL $MYSQL_USER $MYSQL_PASS &

echo "Processing NCI..."
#link to download data is static
sh nci.rrf.sh $NIH_USER $NIH_PASS $MYSQL_USER $MYSQL_PASS &

##### Needs ohdsi archive (archive.zip)
echo "Processing OHDSI..."
sh ohdsi.sh $MYSQL_USER $MYSQL_PASS $OHDSI_ZIP &

echo "Processing EVN..."
sh evn.sh $EVN_USERNAME $EVN_PASSWORD $MYSQL_USER $MYSQL_PASS &

wait
