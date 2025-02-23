#!/bin/sh -f

if [ $# -ne 6 ]; then echo "         Usage:                                                                                                            " 
                      echo "         ./nci.rrf.sh nih-username nih-password mysql_username mysql_password mysql_host mysql_port                                                             "
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
ROOT=${PWD}

# Download nci average 2.5GB, 1.5HRs
#
echo "Download nci, average 2.5GB, 1.5HRs" 
sh $ROOT/nci.download.sh $1 $2


echo "Extract files"
FILE_NAME=$ROOT/nci.zip

# extract unzipped directory name from file 
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
MYSQL_VERSION=$(grep -i mysql $EXTRACT_DIRECTORY/config/$RELEASE/DB_RRF/db.txt)
MYSQL_DIR=$EXTRACT_DIRECTORY/config/$RELEASE/DB_RRF/$MYSQL_VERSION
MYSQL_TABLES=$MYSQL_DIR/mysql_tables.sql
MYSQL_INDEXES=$MYSQL_DIR/mysql_indexes.sql
	
# Depending on OS adjust sql files line delimiter i.e: oxs \n vs \r\n
#
OSX_SED="s/\\\r\\\n/\\\n/g"
NCI_CRLF_SED="s/@LINE_TERMINATION@/'\\\n'/g"
NCI_VARCHAR_50_SED="s/varchar(50)/varchar(1024)/g"
RANK="s/[[:<:]]RANK[[:>:]]/\`RANK\`/g"

sed -e $OSX_SED -e $NCI_CRLF_SED -e $NCI_VARCHAR_50_SED -e $RANK $MYSQL_TABLES > $META_DIRECTORY/mysql_tables_os.sql
cp $MYSQL_INDEXES $META_DIRECTORY/mysql_indexes_os.sql

# Folks in NCI did not include other languages RRFs for MRXW_*
# but meanwhile left the sql statements to fail
# We needed to remove all MRXW_* sql statements except for MRXW_ENG
# since OSX sed has its own regex mind, hndle change in python 
#LANGS='s/(load|DROP|CREATE).*MRXW_((?!ENG)([A-Z]{3}))(.*\n)*.*;//g'
python nci.rrf.py $META_DIRECTORY/mysql_tables_os.sql
python nci.rrf.py $META_DIRECTORY/mysql_indexes_os.sql



# Load RRF files into MySQL
#
echo "Load RRFs into MySQL"
sh $ROOT/nih.sql.sh $META_DIRECTORY nci $3 $4 $5 $6

cat $META_DIRECTORY/mysql.log

echo "NCI Extract Elapsed: " $(($(date -u +%s)-$START)) " Seconds"

