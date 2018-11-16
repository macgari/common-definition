#!/bin/sh -f

###############################################################
##### Home for processing umls, nci, ohdsi, evn pipelines #####
#####  - runs umls, nci, ohdsi, evn pipelines in parallel #####
###############################################################
START=$(date -u +%s)
# update the following parameters

NIH_USER=$nih_username
NIH_PASS=$nih_password

# Dev
#MYSQL_HOME=$MYSQL_HOME                  # /path/mysql57/bin/mysql
#MYSQL_HOST=$mysql_tlvdpcvsdev1_host     # tlvdpcvsdev1.mskcc.org
#MYSQL_PORT=$mysql_tlvdpcvsdev1_port     # 3306
#MYSQL_USER=$mysql_tlvdpcvsdev1_username # cvsuser
#MYSQL_PASS=$mysql_tlvdpcvsdev1_password # *******

# Local
MYSQL_HOME=$MYSQL_HOME
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_USER=root
MYSQL_PASS=root


SOLR_URL="http://localhost:8983/solr"
SOLR_INDEX="cvs8.2"


EVN_USERNAME=$evn_username 
EVN_PASSWORD=$evn_password

# Transformation database, arbitrary database name, where all transformations occur,
# any unique name should be ok 
# This is a staging database, to be deleted after loading, and potentially debugging
TRANSFORMATION_DATABASE=trans

#needs a new url twice a year
UMLS_URL=https://download.nlm.nih.gov/umls/kss/2018AA/umls-2018AA-full.zip

#needs to be downloaded manually and saved in a known path
OHDSI_ZIP=ohdsi-vocab.zip


# example: sh umls.nlm.sh nih_username nih_password https://download.nlm.nih.gov/umls/kss/2018AA/umls-2018AA-full.zip  $mysql_username $mysql_password localhost 3306
# stats: ~4.5GB, ~5 hours
echo "Processing UMLS..."
sh umls.nlm.sh $NIH_USER $NIH_PASS $UMLS_URL $MYSQL_USER $MYSQL_PASS $MYSQL_HOST $MYSQL_PORT &


# example: sh nci.rrf.sh $nih_username $nih_password $mysql_username $mysql_password localhost 3306
# stats: ~ 2.5 GB, ~1.5 hours
echo "Processing NCI..."
sh nci.rrf.sh $NIH_USER $NIH_PASS $MYSQL_USER $MYSQL_PASS $MYSQL_HOST $MYSQL_PORT &

##### Needs ohdsi archive (archive.zip)
# example sh ohdsi.sh $mysql_username $mysql_password localhost 3306 ohdsi-vocab.zip
# stats: ~ 5,419,532 records, ~ 10 min
echo "Processing OHDSI..."
sh ohdsi.sh $MYSQL_USER $MYSQL_PASS $MYSQL_HOST $MYSQL_PORT $OHDSI_ZIP &

# example: sh evn.sh $evn_username $evn_password $mysql_username $mysql_password localhost 3306
# stats: ~600 records, ~2 seconds
echo "Processing EVN..."
sh evn.sh $EVN_USERNAME $EVN_PASSWORD $MYSQL_USER $MYSQL_PASS $MYSQL_HOST $MYSQL_PORT &

wait
echo "Extract is done, next is Transformation"
##### Transformation process
# example ./trans.sh user pass localhost 3306 trans 
# stats: ~ 4,492,052 records, ~ 80 min
./trans.sh $MYSQL_HOST $MYSQL_PORT $MYSQL_USER $MYSQL_PASS $TRANSFORMATION_DATABASE

echo "Transformation is done, next is Load"
##### Load process
# example ./load.sh "http://localhost:8983/solr" "cvs8.2" trans/trans.json
# Warning: Existing Documents will be purged for select Solr index
# Info: trans is the arbitrary database name, the last argument used in the previous step [ $TRANSFORMATION_DATABASE ]
# stats: ~ 4,492,052 records, ~ 40 min
./load.sh $SOLR_URL $SOLR_INDEX $TRANSFORMATION_DATABASE/$TRANSFORMATION_DATABASE.json
echo "NCI Extract Elapsed: " $(($(date -u +%s)-$START)) " Seconds"
echo "All done, please verify"