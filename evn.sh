#!/bin/sh -f

# this setup assuems that a passowrd is not setup on the server
# if one is; then will need to pass it to $MYSQL_HOME/bin/mysql as -p $password
# if one is not set up it would have to be removed

if [ $# -ne  6 ]; then echo "         Usage:                                             						" 
                       echo "         ./evn.sh evn_username evn_password mysql_username mysql_password mysql_host mysql_port      "
                       echo "                                                            					"  
             		   echo "         ./evn.sh evn_username evn_password mysql_username mysql_password mysql_host mysql_port		"
                     
   exit
fi

ROOT=.
DB=evn
MYSQL_HOME=$MYSQL_HOME
EVN_USER=$1
EVN_PASS=$2
USER=$3
PASS=$4
HOST=$5
PORT=$6
EXTRACT_DIRECTORY=$ROOT/$DB

echo "Extract files"

LOG=$EXTRACT_DIRECTORY/mysql.log


rm -rf $EXTRACT_DIRECTORY
mkdir  $EXTRACT_DIRECTORY

sh $ROOT/evn.download.sh $EVN_USER $EVN_PASS

touch $LOG
ef=0

echo "Creating and Loading $DB Database, See $LOG for output"

echo "----------------------------------------" >> $LOG 2>&1
echo "Starting ... `/bin/date`" >> $LOG 2>&1
echo "----------------------------------------" >> $LOG 2>&1
echo "MYSQL_HOME = $MYSQL_HOME" >> $LOG 2>&1
echo "user =       $USER" >> $LOG 2>&1
echo "DB =    $DB" >> $LOG 2>&1


echo "    Create $DB database ... `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv --local-infile -u$USER -p$PASS -h$HOST -P$PORT -e " \
CREATE DATABASE IF NOT EXISTS ${DB} /*!40100 DEFAULT CHARACTER SET utf8 */; \
show warnings \
" >> $LOG 2>&1
if [ $? -ne 0 ]; then ef=1; fi	
echo "finished creating $DB database... `/bin/date`" >> $LOG 2>&1

#Creating concept(concept_id,prefLabel,altLabel,broader,narrower_concept_id)
echo "    Create concept table  ... `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS -h$HOST -P$PORT -e " \
DROP TABLE IF EXISTS ${DB}.concept; \
\
CREATE TABLE ${DB}.concept ( \
	concept_id 			VARCHAR(25)  NULL, \
	prefLabel 			VARCHAR(255) NULL, \
	altLabel	   		VARCHAR(255) NULL, \
	broader 			VARCHAR(25)  NULL, \
	narrower_concept_id VARCHAR(25)  NULL); \
show warnings \
" >> $LOG 2>&1
if [ $? -ne 0 ]; then ef=1; fi	
echo "finished creating  concept table... `/bin/date`" >> $LOG 2>&1


echo "    Loading concept table  ... `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv --local-infile -u $USER -p$PASS  -h$HOST -P$PORT -e " \
load data local infile '${EXTRACT_DIRECTORY}/concept.csv' into table ${DB}.concept FIELDS TERMINATED BY  ','ESCAPED BY '\"' LINES TERMINATED BY '\r\n' IGNORE 1 LINES \
(@concept_id,@prefLabel,@altLabel,@broader,@narrower_concept_id) \
SET \
	concept_id = NULLIF(@concept_id,''), \
	prefLabel = NULLIF(@prefLabel,''), \
	altLabel = NULLIF(@altLabel,''), \
	broader = NULLIF(@broader,''), \
	narrower_concept_id = NULLIF(@narrower_concept_id,''); \
show warnings \
" >> $LOG 2>&1
if [ $? -ne 0 ]; then ef=1; fi	
echo "finished loading concept table... `/bin/date`" >> $LOG 2>&1

echo "    Indexing table(s)  ... `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS  -h$HOST -P$PORT -e " \
CREATE INDEX idx_concept_id  ON ${DB}.concept  (concept_id ASC); \
CREATE INDEX idx_prefLabel ON ${DB}.concept (prefLabel ASC); \
CREATE INDEX idx_altLabel ON ${DB}.concept (altLabel ASC); \
CREATE INDEX idx_broader ON ${DB}.concept (broader ASC); \
CREATE INDEX idx_narrower_concept_id ON ${DB}.concept (narrower_concept_id ASC); \
" >> $LOG 2>&1
if [ $? -ne 0 ]; then ef=1; fi	
echo "finished indexing concept table ... `/bin/date`" >> $LOG 2>&1

#### NO ACCESS TO MAPPING DATASET YET

#Creating mapping(msk_id,oncotree_id)
echo "    Create mapping table  ... `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS  -h$HOST -P$PORT -e " \
DROP TABLE IF EXISTS ${DB}.mapping; \
\
CREATE TABLE ${DB}.mapping ( \
	msk_id 			VARCHAR(25) NULL, \
	oncotree_id 	VARCHAR(25) NULL); \
show warnings \
" >> $LOG 2>&1
if [ $? -ne 0 ]; then ef=1; fi	
echo "finished creating  mapping table... `/bin/date`" >> $LOG 2>&1


echo "    Loading mapping table  ... `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv --local-infile -u $USER -p$PASS  -h$HOST -P$PORT  -e " \
load data local infile '${EXTRACT_DIRECTORY}/mapping.csv' into table ${DB}.mapping FIELDS TERMINATED BY  ',' LINES TERMINATED BY '\r\n' IGNORE 1 LINES \
(@msk_id,@oncotree_id) \
SET \
	msk_id = NULLIF(@msk_id,''), \
	oncotree_id = NULLIF(@oncotree_id,''); \
show warnings \
" >> $LOG 2>&1
if [ $? -ne 0 ]; then ef=1; fi	
echo "finished loading mapping table... `/bin/date`" >> $LOG 2>&1

echo "    Indexing table(s)  ... `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS  -h$HOST -P$PORT -e " \
CREATE INDEX idx_msk_id  ON ${DB}.mapping  (msk_id ASC); \
CREATE INDEX idx_oncotree_id ON ${DB}.mapping (oncotree_id ASC); \

" >> $LOG 2>&1
if [ $? -ne 0 ]; then ef=1; fi	
echo "finished indexing  mapping table ... `/bin/date`" >> $LOG 2>&1


echo "----------------------------------------" >> $LOG 2>&1
if [ $ef -eq 1 ]
then
  echo "There were one or more errors." >> $LOG 2>&1
  retval=-1
else
  echo "Completed without errors." >> $LOG 2>&1
  retval=0
fi
echo "Finished ... `/bin/date`" >> $LOG 2>&1
echo "----------------------------------------" >> $LOG 2>&1
cat $LOG
exit $retval
