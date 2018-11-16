#!/bin/sh -f
if [ $# -ne  3 ];  then echo "         Usage:                                                                  "
                        echo "         ./load.sh "http://localhost:8983/solr" "cvs_2018" path/to/concepts/json/dumped/from/running/trans.sh "
   exit
fi
MYSQL_HOME=$MYSQL_HOME
BASE_URL=$1
INDEX=$2
CONCEPTS_FILE=$3

CMDS=load
CMDSJ=$CMDS/$CMDS.json
LOG=$CMDS/$CMDS.log

HEADERS="Content-type:application/json"
INDEX_URL="$BASE_URL/$INDEX"
INDEX_UPDATE_URL="$INDEX_URL/update?commit=true&wt=json"
INDEX_PURGE_URL="$INDEX_UPDATE_URL&stream.body=<delete><query>*:*</query></delete>"
INDEX_DOCUMENT_COUNT_QUERY="$INDEX_URL/query?q=*:*&rows=0"

rm -rf $CMDS
mkdir $CMDS

# Number of documents per load to index
CHUNK=10000
LINES=$(wc -l < $CONCEPTS_FILE)
echo "Loading $LINES Documents"
CNT=0
echo "WARNING... Purging $INDEX_URL"
curl $INDEX_PURGE_URL --silent --output /dev/null
while read concept
do
  echo "$concept" >> $CMDSJ
  CNT=$(($CNT+1))
  if [ $(( $CNT % $CHUNK )) -eq 0 ]; then
       echo "$CNT : $(( 100*$CNT/$LINES ))%"
       echo "[" > $CMDSJ$CNT
       cat $CMDSJ >> $CMDSJ$CNT
       echo "]" >> $CMDSJ$CNT
 	   curl  -X POST $INDEX_UPDATE_URL -H $HEADERS --silent --output /dev/null --data-binary @$CMDSJ$CNT
 	   LOADED=$(curl $INDEX_DOCUMENT_COUNT_QUERY --silent | grep numFound | awk -F"," '{print $1}' | awk -F ":" '{print $3}')
 	   if [ $LOADED != $CNT ]; then
            echo "LOAD FAILD, at batch $CNT " >> $LOG 2>&1
            echo "ERROR.., check $LOG"
            exit
       fi
 	   echo "" > $CMDSJ
 	   rm -rf $CMDSJ$CNT
    else if [ $CNT -lt $LINES ]; then
	       echo "," >> $CMDSJ 
         fi
  fi
done < $CONCEPTS_FILE
echo "[" > $CMDSJ$CNT
cat $CMDSJ >> $CMDSJ$CNT
echo "]" >> $CMDSJ$CNT
curl  -X POST $INDEX_UPDATE_URL -H $HEADERS --silent --output /dev/null --data-binary @$CMDSJ$CNT
rm -rf $CMDSJ$CNT
rm -rf $CMDSJ
LOADED=$(curl $INDEX_DOCUMENT_COUNT_QUERY --silent | grep numFound | awk -F"," '{print $1}' | awk -F ":" '{print $3}')
 	   if [ $LOADED != $CNT ]; then
    echo "LOAD FAILD, Loaded: $LOADED out of $LINES" >> $LOG
    echo "ERROR.., check $LOG"
fi
echo "$CNT : $(( 100*$CNT/$LINES ))%"
START=$(date -u +%s)
echo "done......"