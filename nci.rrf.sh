#!/bin/sh -f

if [ $# -ne 6 ]; then echo "         Usage:                                                                                                            " 
                      echo "         ./nci.rrf.sh nih-username nih-password mysql_username mysql_password  mysql_password mysql_host mysql_port                                                             "
   exit
fi

START=$(date -u +%s)

# determine OS windows/linux/macos, could be parameterized or automated but for now as is
#
OS=macos

# MetamorphoSys UI
#
META=META

# root directory
#
ROOT=$(pwd)

# Download nci average 2.5GB, 1.5HRs
#
echo "Download nci, average 2.5GB, 1.5HRs" 
sh $ROOT/nci.download.sh $1 $2


echo "Extract files"
FILE_NAME=$ROOT/nci.zip

# extract unzipped directory name from file name: umls-2017AB-full
#
EXTRACT_DIRECTORY=$ROOT/nci

# unzip file FILE_NAME to create EXTRACT_DIRECTORY
#
rm -rf $EXTRACT_DIRECTORY
mkdir $EXTRACT_DIRECTORY
echo "extract nci to " $EXTRACT_DIRECTORY
tar xzf $FILE_NAME --directory $EXTRACT_DIRECTORY

# Specify output directory which will be home for RRF subset files
#
META_DIRECTORY=$EXTRACT_DIRECTORY/$META
RELEASE=$(grep umls.release.name= $EXTRACT_DIRECTORY/release.dat | cut -d'=' -f2)
MYSQL_TABLES=$EXTRACT_DIRECTORY/config/$RELEASE/DB_RRF/Mysql5.5/mysql_tables.sql
MYSQL_INDEXES=$EXTRACT_DIRECTORY/config/$RELEASE/DB_RRF/Mysql5.5/mysql_indexes.sql
	
# Depending on OS adjust sql files line delimiter i.e: oxs \n vs \r\n
#
OSX_SED="s/\\\r\\\n/\\\n/g"
NCI_CRLF_SED="s/@LINE_TERMINATION@/'\\\n'/g"
NCI_VARCHAR_50_SED="s/varchar(50)/varchar(1024)/g"
sed -e $OSX_SED -e $NCI_CRLF_SED -e $NCI_VARCHAR_50_SED $MYSQL_TABLES > $META_DIRECTORY/mysql_tables_os.sql
cp $MYSQL_INDEXES $META_DIRECTORY/mysql_indexes_os.sql

# Load RRF files into MySQL
#
echo "Load RRFs into MySQL"
sh $ROOT/nih.sql.sh $META_DIRECTORY nci $3 $4 $5 $6

cat $META_DIRECTORY/mysql.log

echo "Elapsed: " $(($(date -u +%s)-$START)) " Seconds"

