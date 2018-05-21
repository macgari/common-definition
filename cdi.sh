#!/bin/sh -f

###############################################################
##### Home for processing umls and nci pipelines          #####
#####  - runs umls, nci, ohdsi, evn pipelines in parallel #####
###############################################################

# update the following parameters

NIH_USER=$nih_username
NIH_PASS=$nih_password

# Dev
MYSQL_HOST=$mysql_tlvdpcvsdev1_host # tlvdpcvsdev1.mskcc.org
MYSQL_PORT=$mysql_tlvdpcvsdev1_port # 3306
MYSQL_USER=$mysql_tlvdpcvsdev1_username # cvsuser
MYSQL_PASS=$mysql_tlvdpcvsdev1_password # *******

# Local
# MYSQL_HOST=localhost
# MYSQL_PORT=3306
# MYSQL_USER=root
# MYSQL_PASS=root 

EVN_USERNAME=$evn_username 
EVN_PASSWORD=$evn_password

#needs a new url twice a year
UMLS_URL=https://download.nlm.nih.gov/umls/kss/2017AB/umls-2017AB-full.zip

#needs to be downloaded manually and saved in a known path
OHDSI_ZIP=ohdsi-vocab.zip

chmod 775 *sh

echo "Processing UMLS..."
# example: sh umls.nlm.sh nih_username nih_password https://download.nlm.nih.gov/umls/kss/2017AB/umls-2017AB-full.zip  $mysql_username $mysql_password localhost 3306
# stats: ~4.5GB, ~5 hours
sh umls.nlm.sh $NIH_USER $NIH_PASS $UMLS_URL $MYSQL_USER $MYSQL_PASS $MYSQL_HOST $MYSQL_PORT &


# example: sh nci.rrf.sh $nih_username $nih_password $mysql_username $mysql_password localhost 3306
# stats: ~ 2.5 GB, ~1.5 hours
echo "Processing NCI..."
sh nci.rrf.sh $NIH_USER $NIH_PASS $MYSQL_USER $MYSQL_PASS $MYSQL_HOST $MYSQL_PORT &

##### Needs ohdsi archive (archive.zip)
# example sh ohdsi.sh $mysql_username $mysql_password localhost 3306 ohdsi-vocab.zip 
# stats: ~ 5419532 records, ~ 10 miuntes
echo "Processing OHDSI..."
sh ohdsi.sh $MYSQL_USER $MYSQL_PASS $MYSQL_HOST $MYSQL_PORT $OHDSI_ZIP &

# example: sh evn.sh $evn_username $evn_password $mysql_username $mysql_password localhost 3306
# stats: ~600 recods, ~2 second
echo "Processing EVN..."
sh evn.sh $EVN_USERNAME $EVN_PASSWORD $MYSQL_USER $MYSQL_PASS $MYSQL_HOST $MYSQL_PORT &

wait
