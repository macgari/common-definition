#!/bin/sh -f
#
# For useful information on loading your Metathesaurus subset
# into a MySQL database, please consult the on-line
# documentation at:
#
# http://www.nlm.ohdsi.gov/research/umls/load_scripts.html
#

#
# Database connection parameters
# Please edit these variables to reflect your environment
#

# Note to MySQL users implementing MySQL version 5.6:
# MySQL version 5.6 and above defaults to use the InnoDB storage engine. Users have reported disk space issues while 
# loading RRF data into MySQL 5.6 databases due to default InnoDB settings that store all tables and indexes within the 
# system tablespace. MySQL 5.6.6 now sets the 'innodb_file_per_table' configuration setting to 'on' so that each newly 
# created table and index are assigned a separate .idb data file. Users should read the MySQL documentation for 
# additional information.

# this setup assuems that a passowrd is not setup on the server
# if one is; then will need to pass it to $MYSQL_HOME/bin/mysql as -p $password
# if one is not set up it would have to be removed

ROOT=.
DB=OHDSI
if [ $# -ne 3 ]; then echo "         Usage:                                                          " 
                      echo "         ./ohdsi.sh mysql_username mysql_password ohdsi_vocabularies.zip       				"
                      echo "                                                                "  
             		  echo "         ./ohdsi.sh mysql_username mysql_password /path/to/ohdsi/vocabulary/archive.zip 		"
                     
   exit
fi


MYSQL_HOME=$MYSQL_HOME
USER=$1
PASS=$2

echo "Extract files"
# extract file name from url: umls-2017AB-full.zip
# and extract directory name from file name: umls-2017AB-full
#
FILE_NAME=$3


# extract unzipped directory name from file name: umls-2017AB-full
#
EXTRACT_DIRECTORY=$ROOT/ohdsi

# unzip file FILE_NAME to create EXTRACT_DIRECTORY
#
echo "Extracting " $FILE_NAME " \n    into: "$EXTRACT_DIRECTORY
rm -rf $EXTRACT_DIRECTORY
mkdir $EXTRACT_DIRECTORY
echo "extract ohdsi to " $EXTRACT_DIRECTORY
tar xzf $FILE_NAME --strip 1  --directory $EXTRACT_DIRECTORY

rm -f $EXTRACT_DIRECTORY/mysql.log
touch $EXTRACT_DIRECTORY/mysql.log
ef=0
mrcxt_flag=0
echo "Creating and Loading $DB Database, See $EXTRACT_DIRECTORY/mysql.log for output"

echo "----------------------------------------" >> $EXTRACT_DIRECTORY/mysql.log 2>&1
echo "Starting ... `/bin/date`" >> $EXTRACT_DIRECTORY/mysql.log 2>&1

echo "----------------------------------------" >> $EXTRACT_DIRECTORY/mysql.log 2>&1
echo "MYSQL_HOME = $MYSQL_HOME" >> $EXTRACT_DIRECTORY/mysql.log 2>&1
 
echo "user =       $USER" >> $EXTRACT_DIRECTORY/mysql.log 2>&1
echo "DB =    $DB" >> $EXTRACT_DIRECTORY/mysql.log 2>&1


echo "    Create $DB database ... `/bin/date`" >> $EXTRACT_DIRECTORY/mysql.log 2>&1
$MYSQL_HOME/bin/mysql -vvv --local-infile -u$USER -p$PASS -e " \
CREATE DATABASE IF NOT EXISTS ${DB} /*!40100 DEFAULT CHARACTER SET utf8 */; \
show warnings \
" >> $EXTRACT_DIRECTORY/mysql.log 2>&1
if [ $? -ne 0 ]; then ef=1; fi	
echo "finished creating $DB database... `/bin/date`" >> $EXTRACT_DIRECTORY/mysql.log 2>&1


echo "    Create concept table  ... `/bin/date`" >> $EXTRACT_DIRECTORY/mysql.log 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS -e " \
DROP TABLE IF EXISTS ${DB}.concept; \
\
CREATE TABLE ${DB}.concept ( \
	concept INTEGER NULL, \
	concept_name VARCHAR(255) NULL, \
	domain_id	   VARCHAR(20) NULL, \
	vocabulary_id VARCHAR(20) NULL, \
	concept_class_id VARCHAR(20) NULL, \
	standard_concept VARCHAR(1) NULL, \
	concept_code VARCHAR(50) NULL, \
	valid_start_date DATE  NULL, \
	valid_end_date DATE NULL, \
	invalid_reason VARCHAR(1) NULL); \
show warnings \
" >> $EXTRACT_DIRECTORY/mysql.log 2>&1
if [ $? -ne 0 ]; then ef=1; fi	
echo "finished creating  table(s)... `/bin/date`" >> $EXTRACT_DIRECTORY/mysql.log 2>&1


echo "    Loading table(s)  ... `/bin/date`" >> $EXTRACT_DIRECTORY/mysql.log 2>&1
$MYSQL_HOME/bin/mysql -vvv --local-infile -u $USER -p$PASS -e " \
load data local infile '${EXTRACT_DIRECTORY}/CONCEPT.csv' into table ${DB}.concept FIELDS TERMINATED BY  '\t' LINES TERMINATED BY '\n' IGNORE 1 LINES \
(@concept,@concept_name,@domain_id,@vocabulary_id,@concept_class_id,@standard_concept,@concept_code,@valid_start_date,@valid_end_date,@invalid_reason) \
SET \
	concept = NULLIF(@concept,''), \
	concept_name = NULLIF(@concept_name,''), \
	domain_id = NULLIF(@domain_id,''), \
	vocabulary_id = NULLIF(@vocabulary_id,''), \
	concept_class_id = NULLIF(@concept_class_id,''), \
	standard_concept = NULLIF(@standard_concept,''), \
	concept_code = NULLIF(@fil,''), \
	valid_start_date = NULLIF(@valid_start_date,''), \
	valid_end_date = NULLIF(@valid_end_date,''), \
	invalid_reason = NULLIF(@invalid_reason,''); \
show warnings \
" >> $EXTRACT_DIRECTORY/mysql.log 2>&1
if [ $? -ne 0 ]; then ef=1; fi	
echo "finished loading table(s)... `/bin/date`" >> $EXTRACT_DIRECTORY/mysql.log 2>&1

echo "    Indexing table(s)  ... `/bin/date`" >> $EXTRACT_DIRECTORY/mysql.log 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS -e " \
CREATE INDEX idx_concept_concept_id  ON ${DB}.concept  (concept ASC); \
CREATE INDEX idx_concept_code ON ${DB}.concept (concept_code ASC); \
CREATE INDEX idx_concept_name ON ${DB}.concept (concept_Name ASC); \
CREATE INDEX idx_concept_vocabluary_id ON ${DB}.concept (vocabulary_id ASC); \
CREATE INDEX idx_concept_domain_id ON ${DB}.concept (domain_id ASC); \
CREATE INDEX idx_concept_class_id ON ${DB}.concept (concept_class_id ASC); \
" >> $EXTRACT_DIRECTORY/mysql.log 2>&1
if [ $? -ne 0 ]; then ef=1; fi	
echo "finished indexing  table(s) ... `/bin/date`" >> $EXTRACT_DIRECTORY/mysql.log 2>&1


echo "----------------------------------------" >> $EXTRACT_DIRECTORY/mysql.log 2>&1
if [ $ef -eq 1 ]
then
  echo "There were one or more errors." >> $EXTRACT_DIRECTORY/mysql.log 2>&1
  retval=-1
else
  echo "Completed without errors." >> $EXTRACT_DIRECTORY/mysql.log 2>&1
  retval=0
fi
echo "Finished ... `/bin/date`" >> $EXTRACT_DIRECTORY/mysql.log 2>&1
echo "----------------------------------------" >> $EXTRACT_DIRECTORY/mysql.log 2>&1
cat $EXTRACT_DIRECTORY/mysql.log
exit $retval
