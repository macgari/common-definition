#!/bin/sh -f

##########################################################
##### Home for processing umls and nci pipelines     #####
#####  - runs umls, nci, ohdsi pipelines in parallel #####
##########################################################

# update the following parameters
NIH_USER=$nih_username
NIH_PASS=$nih_password
MYSQL_USER=$mysql_username
MYSQL_PASS=$mysql_password
UMLS_URL=https://download.nlm.nih.gov/umls/kss/2017AB/umls-2017AB-full.zip
OHDSI_ZIP=ohdsi-vocab.zip

echo "Processing UMLS..."
sh umls.nlm.sh $NIH_USER $NIH_PASS $UMLS_URL $MYSQL_USER $MYSQL_PASS &


echo "Processing NCI..."
sh nci.rrf.sh $NIH_USER $NIH_PASS $MYSQL_USER $MYSQL_PASS &

##### Needs ohdsi files (archive.zip)
echo "Processing OHDSI..."
sh ohdsi.sh $MYSQL_USER $MYSQL_PASS $OHDSI_ZIP &

wait
