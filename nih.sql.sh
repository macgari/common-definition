#!/bin/sh -f
#
# For useful information on loading your Metathesaurus subset
# into a MySQL database, please consult the on-line
# documentation at:
#
# http://www.nlm.nih.gov/research/umls/load_scripts.html
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

ROOT=$1
DB=$2
if [ $# -ne 4 ]; then echo "         Usage:                                                                   " 
                      echo "         ./nih.sql.sh META_Directory NIH_DATABASE mysql_username mysql_password "
                      echo "                                                                                  "  
		              echo "         ./nih.sql.sh /usr/data2017AB-full/META umls mysql_username mysql_password"
                      echo "         ./nih.sql.sh  /usr/data/nci/META nci mysql_username mysql_password"                      
   exit
fi


cd $ROOT
MYSQL_HOME=$MYSQL_HOME
USER=$3
PASS=$4

rm -f mysql.log
touch mysql.log
ef=0
mrcxt_flag=0
echo "See mysql.log for output"

echo "----------------------------------------" >> mysql.log 2>&1
echo "Starting ... `/bin/date`" >> mysql.log 2>&1

echo "----------------------------------------" >> mysql.log 2>&1
echo "MYSQL_HOME = $MYSQL_HOME" >> mysql.log 2>&1

echo "user =       $USER" >> mysql.log 2>&1
echo "DB =    $DB" >> mysql.log 2>&1

# Create empty mrcxt if it doesn't exist, expected by mysql_tables.sql script
if [ ! -f MRCXT.RRF ]; then mrcxt_flag=1; fi
if [ ! -f MRCXT.RRF ]; then `touch MRCXT.RRF`; fi


echo "    Create database $DB if not created  ... `/bin/date`" >> mysql.log 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS -e "CREATE DATABASE IF NOT EXISTS $DB /*!40100 DEFAULT CHARACTER SET utf8 */;" >> mysql.log 2>&1
if [ $? -ne 0 ]; then ef=1; fi

echo "finished creating $DB database ... `/bin/date`" >> mysql.log 2>&1


echo "    Create and load tables ... `/bin/date`" >> mysql.log 2>&1
$MYSQL_HOME/bin/mysql -vvv --local-infile -u $USER -p$PASS  $DB < mysql_tables_os.sql >> mysql.log 2>&1
if [ $? -ne 0 ]; then ef=1; fi

echo "finished loading tables ... `/bin/date`" >> mysql.log 2>&1


echo "    Create indexes ... `/bin/date`" >> mysql.log 2>&1
$MYSQL_HOME/bin/mysql -vvv  --local-infile -u $USER  -p$PASS  $DB < mysql_indexes_os.sql >> mysql.log 2>&1
if [ $? -ne 0 ]; then ef=1; fi


echo "finished indexes ... `/bin/date`" >> mysql.log 2>&1

if [ $mrcxt_flag -eq 1 ]
then
rm -f MRCXT.RRF
echo "DROP TABLE IF EXISTS MRCXT;" >> drop_mrcxt.sql
$MYSQL_HOME/bin/mysql -vvv --local-infile -u $USER -p$PASS $DB < drop_mrcxt.sql >> mysql.log 2>&1
if [ $? -ne 0 ]; then ef=1; fi
rm -f drop_mrcxt.sql
fi


echo "----------------------------------------" >> mysql.log 2>&1
if [ $ef -eq 1 ]
then
  echo "There were one or more errors." >> mysql.log 2>&1
  retval=-1
else
  echo "Completed without errors." >> mysql.log 2>&1
  retval=0
fi
echo "Finished ... `/bin/date`" >> mysql.log 2>&1
echo "----------------------------------------" >> mysql.log 2>&1
exit $retval
