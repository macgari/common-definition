#!/bin/sh -f
if [ $# -ne  1 ];  then echo "         Usage:                                                                  " 
                        echo "         ./load.sh  path/to/concepts/json/dumped/from/running/trans.sh "
   exit
fi
MYSQL_HOME=$MYSQL_HOME
CONCEPTS_FILE=$1
LOG=$CONCEPTS_FILE.log
HEADERS="Content-type:application/json"
SOLR_URL="http://localhost:8983/solr/cvs8/update?commit=true&wt=json"
CMDS=cmds
rm -rf $CMDS
mkdir $CMDS
CMDSJ=$CMDS/$CMDS.json
CHUNK=10000
LINES=$(wc -l < $CONCEPTS_FILE)
CNT=0
while read concept
do
  echo "$concept" >> $CMDSJ
  CNT=$(($CNT+1))
  if [ $(( $CNT % $CHUNK )) -eq 0 ]; then
       echo "$(( 100*$CNT/$LINES ))%" 
       echo "[" > $CMDSJ$CNT
       cat $CMDSJ >> $CMDSJ$CNT
       echo "]" >> $CMDSJ$CNT
       echo "'$CMDSJ$CNT': "
 	     curl  -X POST $SOLR_URL -H $HEADERS --data-binary @$CMDSJ$CNT >> $LOG
 	     echo "" > $CMDSJ 
    else if [ $CNT -lt $LINES ]; then
	       echo "," >> $CMDSJ 
         fi      
  fi
done < $CONCEPTS_FILE
echo "[" > $CMDSJ$CNT
cat $CMDSJ >> $CMDSJ$CNT
echo "]" >> $CMDSJ$CNT
curl  -X POST $SOLR_URL -H $HEADERS --data-binary @$CMDSJ$CNT >> $LOG
echo "done......"