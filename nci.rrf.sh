#!/bin/sh -f

if [ $# -ne 4 ]; then echo "         Usage:                                                                                                            " 
                      echo "         ./nci.rrf.sh nih-username nih-password mysql_username mysql_password                                                          "
   exit
fi
chmod 775 *sh
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


# subset configurations
# should instead auto-generate -- revisit
#
#CONFIG_FILE=$ROOT/nci.rrf.cfg


# Download umls average 2.5GB, 1.5HRs
#
echo "Download nci, average 2.5GB, 1.5HRs" 
sh $ROOT/nci.download.sh $1 $2


echo "Extract files"
# extract file name from url: umls-2017AB-full.zip
# and extract directory name from file name: umls-2017AB-full
#
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

# Specify JAVA_HOME
#
#JAVA_HOME=jre/$OS

# Specify output directory which will be home for RRF subset files
#
META_DIRECTORY=$EXTRACT_DIRECTORY/$META
#META_SUB_DIRECTORY=$META_DIRECTORY/$META
#mkdir $META_SUB_DIRECTORY
RELEASE=$(grep umls.release.name= $EXTRACT_DIRECTORY/release.dat | cut -d'=' -f2)
MYSQL_TABLES=$EXTRACT_DIRECTORY/config/$RELEASE/DB_RRF/Mysql5.5/mysql_tables.sql
MYSQL_INDEXES=$EXTRACT_DIRECTORY/config/$RELEASE/DB_RRF/Mysql5.5/mysql_indexes.sql

# Install nci sources	
#
#cd $EXTRACT_DIRECTORY
#CLASSPATH=:lib/jpf-boot.jar
#echo "Install nci sources"
#$JAVA_HOME/bin/java -cp $CLASSPATH -Djava.awt.headless=true -Djpf.boot.config=etc/subset.boot.properties -Dlog4j.configuration=etc/subset.log4j.properties -Dinput.uri=$META_DIRECTORY -Doutput.uri=$META_SUB_DIRECTORY -Dmmsys.config.uri=$CONFIG_FILE -Xms4G -Xmx4G org.java.plugin.boot.Boot
#cd $ROOT
	
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
sh $ROOT/nih.sql.sh $META_DIRECTORY nci $3 $4

cat $META_DIRECTORY/mysql.log

echo "Elapsed: " $(($(date -u +%s)-$START)) " Seconds"

