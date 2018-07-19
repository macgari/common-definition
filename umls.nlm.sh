#!/bin/sh -f

if [ $# -ne 7 ]; then echo "         Usage:                                                                                                            " 
                      echo "         ./umls.nlm.sh nih-username nih-password download_URL mysql_username mysql_password mysql_host mysql_port                                                          "
                      echo "                                                                                                                           "  
		              echo "         ./umls.nlm.sh nih_username nih_password https://download.nlm.nih.gov/umls/kss/2018AA/umls-2018AA-full.zip mysql_username mysql_password  mysql_host mysql_port " 

   exit
fi

START=$(date -u +%s)

# determine OS windows/linux/macos, could be parameterized or automated but for now as is
#
OS=macos

# MetamorphoSys UI
#
MetamorphoSys=mmsys.zip
META=META


# root directory
#
ROOT=${PWD}

# subset configurations
# should instead auto-generate -- revisit
#
CONFIG_FILE=$ROOT/umls.nlm.cfg


# Download umls average 4.5GB, 5HRs
#
echo "Download umls, average size and time: 4.5GB, 5HRs respectively" 
sh $ROOT/umls.download.sh $1 $2 $3


# Extract files
# example of a url: https://download.nlm.nih.gov/umls/kss/2018AA/umls-2018AA-full.zip
#
echo "Extract files"
URL=$3


# extract file name from url: umls-2018AA-full.zip
# and extract directory name from file name: umls-2018AA-full
#
FILE_NAME="${URL##*/}"
DIRECTORY_NAME="${FILE_NAME%.*}"

# extract unzipped directory name from file name: umls-2018AA-full
#
EXTRACT_DIRECTORY=$ROOT/$DIRECTORY_NAME

echo "clean up previous space @ " $EXTRACT_DIRECTORY
rm -rf $EXTRACT_DIRECTORY
mkdir $EXTRACT_DIRECTORY

echo "extract $FILE_NAME @ " $EXTRACT_DIRECTORY
tar xzf $FILE_NAME --strip 1  --directory $EXTRACT_DIRECTORY


# Specify MetamorphoSys directory, and extract to EXTRACT_DIRECTORY
#
echo "extract MetamorphoSys"
tar xzf $EXTRACT_DIRECTORY/$MetamorphoSys --directory $EXTRACT_DIRECTORY


# Specify output directory which will be home for RRF subset files
#
META_DIRECTORY=$EXTRACT_DIRECTORY/$META
mkdir -p $META_DIRECTORY


# Install umls sources
#
cd $EXTRACT_DIRECTORY
JAVA_HOME=jre/$OS
CLASSPATH=:lib/jpf-boot.jar
echo "Install umls sources"
$JAVA_HOME/bin/java \
-cp $CLASSPATH \
-Djava.awt.headless=true \
-Djpf.boot.config=etc/subset.boot.properties \
-Dlog4j.configuration=etc/subset.log4j.properties \
-Dinput.uri=$EXTRACT_DIRECTORY \
-Doutput.uri=$META_DIRECTORY \
-Dmmsys.config.uri=$CONFIG_FILE \
-Xms4G -Xmx4G org.java.plugin.boot.Boot

cd $ROOT

# Depending on OS adjust sql files line delimiter i.e: oxs \n vs \r\n
#
OSX_SED="s/\\\r\\\n/\\\n/g"
sed -e $OSX_SED $META_DIRECTORY/mysql_tables.sql > $META_DIRECTORY/mysql_tables_os.sql
cp $META_DIRECTORY/mysql_indexes.sql  $META_DIRECTORY/mysql_indexes_os.sql


# Load RRF files into MySQL
#
echo "Load RRFs into MySQL"
sh $ROOT/nih.sql.sh $META_DIRECTORY umls $4 $5 $6 $7

cat $META_DIRECTORY/mysql.log

echo "UMLS Extract, elapsed: " $(($(date -u +%s)-$START)) " Seconds"
