#!/bin/sh -f
#

if [ $# -ne 6 ]; then echo "         Usage:                                                                   						" 
                      echo "         ./nih.sql.sh META_Directory NIH_DATABASE mysql_username mysql_password mysql_host mysql_port "
                      echo "                                                                                  "  
		              echo "         ./nih.sql.sh /usr/data2018AA-full/META umls mysql_username mysql_password mysql_host mysql_port "
                      echo "         ./nih.sql.sh  /usr/data/nci/META nci mysql_username mysql_password  mysql_host mysql_port "                      
   exit
fi




MYSQL_HOME=$MYSQL_HOME
ROOT=$1
DB=$2
USER=$3
PASS=$4
HOST=$5
PORT=$6

cd $ROOT
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
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS -h$HOST -P$PORT -e "CREATE DATABASE IF NOT EXISTS $DB /*!40100 DEFAULT CHARACTER SET utf8 */;" >> mysql.log 2>&1
if [ $? -ne 0 ]; then ef=1; fi

echo "finished creating $DB database ... `/bin/date`" >> mysql.log 2>&1


echo "    Create and load tables ... `/bin/date`" >> mysql.log 2>&1
$MYSQL_HOME/bin/mysql -vvv --local-infile -u $USER -p$PASS  -h$HOST -P$PORT $DB < mysql_tables_os.sql >> mysql.log 2>&1
if [ $? -ne 0 ]; then ef=1; fi

echo "finished loading tables ... `/bin/date`" >> mysql.log 2>&1


echo "    Create indexes ... `/bin/date`" >> mysql.log 2>&1
$MYSQL_HOME/bin/mysql -vvv  --local-infile -u $USER  -p$PASS  -h$HOST -P$PORT  $DB < mysql_indexes_os.sql >> mysql.log 2>&1
if [ $? -ne 0 ]; then ef=1; fi


echo "finished indexes ... `/bin/date`" >> mysql.log 2>&1

if [ $mrcxt_flag -eq 1 ]
then
rm -f MRCXT.RRF
echo "DROP TABLE IF EXISTS MRCXT;" >> drop_mrcxt.sql
$MYSQL_HOME/bin/mysql -vvv --local-infile -u $USER -p$PASS  -h$HOST -P$PORT  $DB < drop_mrcxt.sql >> mysql.log 2>&1
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
