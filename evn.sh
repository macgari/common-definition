#!/bin/sh -f

# this setup assumes that a passowrd is not setup on the server
# if one is; then will need to pass it to $MYSQL_HOME/bin/mysql as -p $password
# if one is not set up it would have to be removed



if [ $# -ne  6 ]; then echo "         Usage:                                             						" 
                       echo "         ./evn.sh evn_username evn_password mysql_username mysql_password mysql_host mysql_port      "
                       echo "                                                            					"  
             		   echo "         ./evn.sh evn_username evn_password mysql_username mysql_password mysql_host mysql_port		"
                     
   exit
fi

ROOT=${PWD}
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
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS -h$HOST -P$PORT -D${DB} -e " \
DROP TABLE IF EXISTS concept; \
\
CREATE TABLE concept ( \
	concept_id 			VARCHAR(25)  NULL, \
	prefLabel 			VARCHAR(255) NULL, \
	altLabel	   		VARCHAR(255) NULL);\
show warnings \
" >> $LOG 2>&1
if [ $? -ne 0 ]; then ef=1; fi	
echo "finished creating  concept table... `/bin/date`" >> $LOG 2>&1


echo "    Loading concept table  ... `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv --local-infile -u $USER -p$PASS  -h$HOST -P$PORT -D${DB} -e " \
load data local infile '${EXTRACT_DIRECTORY}/concept.csv' into table concept FIELDS TERMINATED BY  ','ESCAPED BY '\"' LINES TERMINATED BY '\r\n' IGNORE 1 LINES \
(@concept_id,@prefLabel,@altLabel) \
SET \
	concept_id = trim(NULLIF(@concept_id,'')), \
	prefLabel = trim(NULLIF(@prefLabel,'')), \
	altLabel = trim(NULLIF(@altLabel,'')); \
show warnings \
" >> $LOG 2>&1
if [ $? -ne 0 ]; then ef=1; fi	
echo "finished loading concept table... `/bin/date`" >> $LOG 2>&1

echo "    Indexing table(s)  ... `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS  -h$HOST -P$PORT -D${DB} -e " \
CREATE INDEX idx_concept_id  ON concept  (concept_id ASC); \
CREATE INDEX idx_prefLabel ON concept (prefLabel ASC); \
CREATE INDEX idx_altLabel ON concept (altLabel ASC); \
" >> $LOG 2>&1
if [ $? -ne 0 ]; then ef=1; fi	
echo "finished indexing concept table ... `/bin/date`" >> $LOG 2>&1



#Creating mapping(msk_id,oncotree_id)
echo "    Create mapping table  ... `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS  -h$HOST -P$PORT -D${DB} -e " \
DROP TABLE IF EXISTS mapping; \
\
CREATE TABLE mapping ( \
	msk_id 			VARCHAR(25) NULL, \
	oncotree_id 	VARCHAR(25) NULL); \
show warnings \
" >> $LOG 2>&1
if [ $? -ne 0 ]; then ef=1; fi	
echo "finished creating  mapping table... `/bin/date`" >> $LOG 2>&1


echo "    Loading mapping table  ... `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv --local-infile -u $USER -p$PASS  -h$HOST -P$PORT  -D${DB} -e " \
load data local infile '${EXTRACT_DIRECTORY}/mapping.csv' into table mapping FIELDS TERMINATED BY  ',' LINES TERMINATED BY '\r\n' IGNORE 1 LINES \
(@msk_id,@oncotree_id) \
SET \
	msk_id = NULLIF(@msk_id,''), \
	oncotree_id = NULLIF(@oncotree_id,''); \
show warnings \
" >> $LOG 2>&1
if [ $? -ne 0 ]; then ef=1; fi	
echo "finished loading mapping table... `/bin/date`" >> $LOG 2>&1

echo "    Indexing table(s)  ... `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS  -h$HOST -P$PORT -D ${DB} -e " \
CREATE INDEX idx_msk_id  ON mapping  (msk_id ASC); \
CREATE INDEX idx_oncotree_id ON mapping (oncotree_id ASC); \
" >> $LOG 2>&1
if [ $? -ne 0 ]; then ef=1; fi	
echo "finished indexing  mapping table ... `/bin/date`" >> $LOG 2>&1

echo "    Create oncotree  ... `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS  -h$HOST -P$PORT -D${DB} -e " \
DROP TABLE IF EXISTS oncotree; \
create table oncotree as \
( \
select distinct \
	 msk_id \
	,prefLabel \
	,altLabel \
from \
	concept \
		inner join \
			mapping \
		on \
			concept.concept_id = mapping.oncotree_id \
where \
    msk_id is not null \
order by \
         msk_id \
		,prefLabel \
		,altLabel \
); \
" >> $LOG 2>&1
if [ $? -ne 0 ]; then ef=1; fi	
echo "finished creating  oncotree table ... `/bin/date`" >> $LOG 2>&1


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



##############################################################################################

