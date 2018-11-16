#!/bin/sh -f


#########################################################################################################

# edit my.cnf, add/modift these parameters

# innodb_buffer_pool_size = 8G
# innodb_buffer_pool_chunk_size = 1G


#########################################################################################################

# stats
# {step: "Create, load, and index NCI   Crosswalks assisting table  ", rows: 6M,     time: 5  min}
# {step: "Create, load, and index OHDSI Crosswalks assisting table  ", rows: 1M,     time: 3  min}
# {step: "Create, load, and index EVN   Crosswalks assisting table  ", rows: 600,    time: 1  min}
# {step: "Create, load ,and index preflabel table                   ", rows: 3.5M,   time: 1  min}
# {step: "Create, and load altlabel table                           ", rows: 0.8M,   time: 1  min}
# {step: "Create, load ,and index semtype table                     ", rows: 4M,     time: 1  min}
# {step: "Create, load ,and index semrel table                      ", rows: 8.6M,   time: 11 min}
# {step: "Create, load ,and index dynrel table                      ", rows: 8.6M,   time: 11 min}
# {step: "Create, load ,and index dynrel table                      ", rows: 1.2M,   time: 5  min}
# {step: "Create, load ,and index child table                       ", rows: 1.2M,   time: 5  min}
        
# {step: "Collect crosswalk from NCI into crosswalk table           ", rows: 3.7M,   time: 1  min}
# {step: "Collect crosswalk from NCI into altlabel table            ", rows: 2.8M,   time: 1  min}
        
# {step: "Collect crosswalk from OHDSI into crosswalk table         ", rows: 1M,     time: 4  min}
# {step: "Collect crosswalk from OHDSI into altlabel table          ", rows: 1M,     time: 1  min}
        
# {step: "Collect crosswalk from EVN into crosswalk table           ", rows: 600,    time: 1  min}
# {step: "Collect crosswalk from EVN into altlabel table            ", rows: 600,    time: 1  min}
        
# {step: "Create altlabel Indices                                   ", rows: 000,    time: 5  min}
# {step: "Create crosswalk Indices                                  ", rows: 000,    time: 1  min}
        
        
# {step: "Dedupe, index, rollup, index preflabel                    ", rows: 000,    time: 3  min}
# {step: "Dedupe, index, rollup, index altlabel                     ", rows: 000,    time: 3  min}
# {step: "Dedupe, index, rollup, index semtype                      ", rows: 000,    time: 1  min}
# {step: "Dedupe, index, rollup, index semrel                       ", rows: 000,    time: 4  min}
# {step: "Dedupe, index, rollup, index dynrel                       ", rows: 000,    time: 5  min}
# {step: "Dedupe, index, rollup, index parent                       ", rows: 000,    time: 1  min}
# {step: "Dedupe, index, rollup, index child                        ", rows: 000,    time: 1  min}
# {step: "Dedupe, index, rollup, index crosswalk                    ", rows: 000,    time: 3  min}

# {step: "Indexing rfs                                              ", rows: 000,    time: 2  min}
# {step: "Rollup attributes as k,v by concept export json documents ", rows: 000,    time: 4  min}

# {total                                                                                 : 1:26 h}



if [ $# -ne  5 ];  then echo "         Usage:                                                                  " 
                        echo "         ./tr.sh mysql_username mysql_password mysql_host mysql_port  database   "
   exit
fi

ROOT=${PWD}
MYSQL_HOME=$MYSQL_HOME
HOST=$1
PORT=$2
USER=$3
PASS=$4
DB=$5

EXTRACT_DIRECTORY=$ROOT/$DB
LOG=$EXTRACT_DIRECTORY/$DB.log
CONCEPTS_FILE=$EXTRACT_DIRECTORY/$DB.json
rm -rf $EXTRACT_DIRECTORY
mkdir $EXTRACT_DIRECTORY

echo "Begin transformation process, check progress at $LOG"

# Create a database where all transformation occure
echo "Create ${DB} database... `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS  -h$HOST -P$PORT -e " \
drop database if exists ${DB}; \
create database ${DB} /*!40100  default character set utf8 */; \
show warnings \
" >> $LOG 2>&1 
if [[ $? -ne 0 ]] ; then 
    exit 1 
fi 

# create json cleanning function jclean 
echo "Creating solr/json cleaning function... `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS  -h$HOST -P$PORT -e " \
DROP FUNCTION IF EXISTS ${DB}.jclean;
DELIMITER $$
CREATE FUNCTION ${DB}.jclean (s text)
  RETURNS text 
  DETERMINISTIC
  begin
  declare sq,bs,dq char;
  set sq = CHAR(39 using ASCII);
  set bs = CHAR(92 using ASCII);
  set dq = CHAR(34 using ASCII);
  set s = replace(s, sq, repeat(sq,2));
  set s = replace(s, bs, repeat(bs,2));
  set s = replace(s, dq, repeat(dq,2));
  RETURN s;
  end$$
DELIMITER ;
" >> $LOG 2>&1
if [[ $? -ne 0 ]] ; then 
 exit 1 
fi 


# create nci crosswalks assisting table 
echo "Create, load, and index NCI Crosswalks table... `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS  -h$HOST -P$PORT -e " \
drop table if exists ${DB}.nci_cw; \
create table ${DB}.nci_cw as (select distinct concat('MSK',substr(cui,2)) as cui, sab, code, trim(str) as str, ispref, ts, stt from nci.mrconso where lat='ENG' and suppress ='N'); \
create index idx_cui on ${DB}.nci_cw(cui ASC); \
create index idx_sab on ${DB}.nci_cw(sab ASC); \
create index idx_code on ${DB}.nci_cw(code ASC); \
create fulltext index idx_str on ${DB}.nci_cw(str ASC); \
create index idx_ispref on ${DB}.nci_cw(ispref ASC); \
create index idx_ts on ${DB}.nci_cw(ts ASC); \
create index idx_stt on ${DB}.nci_cw(stt ASC); \
show warnings \
" >> $LOG 2>&1
if [[ $? -ne 0 ]] ; then 
 exit 1 
fi 

# Create ohdsi assisting table
# stats:  { env: local, records:~ 1M, elapsed:~ 3 min }
echo "Create, load and index OHDSI Crosswalks table... `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS  -h$HOST -P$PORT  -e " \
drop table if exists ${DB}.ohdsi_cw; \
create table ${DB}.ohdsi_cw as ( \
select distinct \
 concat('MSK',substr(o.concept,2)) as cui, \
    trim(o.concept_name) as str, \
    u.sab, \
    u.code \
from \
 ( select distinct \
   concept, \
   concept_name, \
            concept_code, \
   vocabulary_id \
  from \
   ohdsi.concept \
  where \
   invalid_reason is null \
            and concept is not null \
            and concept_code  is not null \
   and vocabulary_id is not null \
   and date(valid_end_date) > current_date() \
    ) o \
    left join \
  cdi.ohdsi_to_umls o2u \
  on o.vocabulary_id = o2u.ohdsi_sab \
    inner join \
  ( \
  select distinct \
      cui, \
   sab, \
   code \
  from \
   umls.mrconso \
  where \
   suppress = 'N' \
            and \
            lat = 'ENG' \
  ) u \
  on \
   o.concept_code = u.code \
   and \
            ( \
    (o2u.umls_sab = u.sab and o2u.umls_sab is not null) \
                or \
                (o.vocabulary_id = u.sab and o2u.umls_sab is null) \
      ) \
); \
create index idx_cui  on ${DB}.ohdsi_cw(cui  ASC); \
create index idx_sab  on ${DB}.ohdsi_cw(sab  ASC); \
create index idx_code on ${DB}.ohdsi_cw(code ASC); \
create index idx_str  on ${DB}.ohdsi_cw(str  ASC); \
show warnings \
" >> $LOG 2>&1
if [[ $? -ne 0 ]] ; then  
 exit 1 
fi 


# Create evn assisting table
# stats:  { env: local, records:~ 1M, elapsed:~ 3 min }
echo "Collect crosswalk from EVN/ONCOTREE into crosswalk table... `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS  -h$HOST -P$PORT  -e " \
drop table if exists ${DB}.evn_cw; \
create table ${DB}.evn_cw as ( \
select distinct \
    msk_id as cui, \
    prefLabel as str, \
    'ONCOTREE' as sab, \
    altLabel as code \
from \
 evn.oncotree \
); \
create index idx_cui  on ${DB}.evn_cw(cui  ASC); \
create index idx_sab  on ${DB}.evn_cw(sab  ASC); \
create index idx_code on ${DB}.evn_cw(code ASC); \
create index idx_str  on ${DB}.evn_cw(str  ASC); \
show warnings \
" >> $LOG 2>&1
if [[ $? -ne 0 ]] ; then  
 exit 1 
fi 


# Create, load ,and index preflabel table
echo "Create, load ,and index preflabel table... `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS  -h$HOST -P$PORT  -e " \
DROP TABLE IF EXISTS ${DB}.preflabel; \
CREATE TABLE ${DB}.preflabel as (
SELECT \
 concat('MSK',substr(cui,2)) as concept_id, \
 trim(str) as attribute_val \
FROM \
 umls.mrconso \
WHERE \
 lat      = 'ENG' and \
 ISPREF   = 'Y' and \
 TS       = 'P' and \
 suppress = 'N' and \
 stt      = 'PF' ) \
; \
CREATE INDEX idx_concept_id  ON ${DB}.preflabel  (concept_id ASC); \
CREATE FULLTEXT INDEX idx_attribute_val ON ${DB}.preflabel (attribute_val ASC); \
show warnings \
" >> $LOG 2>&1
if [[ $? -ne 0 ]] ; then  
 exit 1 
fi 


# Create, and load altlabel table
# delay indexing until crosswalks are fully collected
echo "Create, and load altlabel table... `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS  -h$HOST -P$PORT  -e " \
DROP TABLE IF EXISTS ${DB}.altlabel; \
CREATE TABLE ${DB}.altlabel as ( \
  SELECT \
  distinct \
 concat('MSK',substr(cui,2)) as concept_id, \
 trim(str) as attribute_val \
FROM \
 umls.mrconso \
WHERE \
 lat      = 'ENG' and \
 ISPREF  != 'Y' and \
 suppress = 'N' \
); \
show warnings \
" >> $LOG 2>&1
if [[ $? -ne 0 ]] ; then  
 exit 1 
fi 



# Create, load ,and index semtype table... 
echo "Create, load ,and index semtype table... `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS  -h$HOST -P$PORT  -e " \
DROP TABLE IF EXISTS ${DB}.semtype; \
CREATE TABLE ${DB}.semtype as ( \
SELECT \
  distinct \
 concat('MSK',substr(cui,2)) as concept_id, \
 trim(sty) as attribute_val \
FROM \
 umls.mrsty \
  ); \
CREATE INDEX idx_concept_id  ON ${DB}.semtype  (concept_id ASC); \
CREATE INDEX idx_attribute_val ON ${DB}.semtype (attribute_val ASC); \
show warnings \
" >> $LOG 2>&1
if [[ $? -ne 0 ]] ; then  
 exit 1 
fi 


# Create, load ,and index semrel table... 
echo "Create, load ,and index semrel table... `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS  -h$HOST -P$PORT  -e " \
DROP TABLE IF EXISTS ${DB}.semrel; \
CREATE TABLE ${DB}.semrel as ( \
  SELECT \
 concat('MSK',substr(rel.cui2,2)) as concept_id, \
 concat(trim(rel.rela),'|',concat('MSK',substr(rel.cui1,2)))  as attribute_val \
FROM \
 (select distinct cui1, cui2, rela from umls.mrrel where rel = 'RO' and suppress = 'N' and rela is not null) rel \
  inner join \
 (select distinct cui from umls.mrconso where lat = 'ENG' and ISPREF = 'Y' and TS = 'P' and suppress = 'N' and stt = 'PF' ) con \
    on \
   rel.cui1 = con.cui \
  ); \
CREATE INDEX idx_concept_id  ON ${DB}.semrel  (concept_id ASC); \
CREATE INDEX idx_attribute_val ON ${DB}.semrel (attribute_val ASC); \
show warnings \
" >> $LOG 2>&1
if [[ $? -ne 0 ]] ; then  
 exit 1 
fi 



# Create, load ,and index dynrel table... 
echo "Create, load ,and index dynrel table... `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS  -h$HOST -P$PORT  -e " \
DROP TABLE IF EXISTS ${DB}.dynrel; \
CREATE TABLE ${DB}.dynrel as ( \
SELECT \
 concat('MSK',substr(rel.cui2,2)) as concept_id, \
 concat('_', trim(rel.rela)) as attribute_key, \
 concat('MSK',substr(rel.cui1,2)) as attribute_val \
FROM \
 (select distinct cui1, cui2, rela from umls.mrrel where rel = 'RO' and suppress = 'N' and rela is not null) rel \
  inner join \
 (select distinct cui from umls.mrconso where lat = 'ENG' and ISPREF = 'Y' and TS = 'P' and suppress = 'N' and stt = 'PF' ) con \
    on \
   rel.cui1 = con.cui \
  ); \
CREATE INDEX idx_concept_id  ON ${DB}.dynrel  (concept_id ASC); \
CREATE INDEX idx_attribute_key ON ${DB}.dynrel (attribute_key ASC); \
CREATE INDEX idx_attribute_val ON ${DB}.dynrel (attribute_val ASC); \
show warnings \
" >> $LOG 2>&1
if [[ $? -ne 0 ]] ; then  
 exit 1 
fi 

# Create, load ,and index parent table... 
echo "Create, load ,and index oncept_parent table... `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS  -h$HOST -P$PORT  -e " \
DROP TABLE IF EXISTS ${DB}.parent; \
CREATE TABLE ${DB}.parent as ( \
SELECT \
 concat('MSK',substr(rel.cui1,2)) as concept_id, \
 concat('MSK',substr(rel.cui2,2)) as attribute_val \
FROM \
 (select distinct cui1, cui2, rela from umls.mrrel where cui1 != cui2 and rel = 'PAR' and suppress = 'N' and rela is not null) rel \
  inner join \
 (select distinct cui from umls.mrconso where lat = 'ENG' and ISPREF = 'Y' and TS = 'P' and suppress = 'N' and stt = 'PF' ) con \
    on \
   rel.cui2 = con.cui \
  ); \
CREATE INDEX idx_concept_id  ON ${DB}.parent (concept_id ASC); \
CREATE INDEX idx_attribute_val ON ${DB}.parent (attribute_val ASC); \
show warnings \
" >> $LOG 2>&1
if [[ $? -ne 0 ]] ; then  
 exit 1 
fi 

# Create, load ,and index child table... 
echo "Create, load ,and index child table... `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS  -h$HOST -P$PORT  -e " \
DROP TABLE IF EXISTS ${DB}.child; \
CREATE TABLE ${DB}.child as ( \
SELECT \
 concat('MSK',substr(rel.cui1,2)) as concept_id, \
 concat('MSK',substr(rel.cui2,2)) as attribute_val \
FROM \
 (select distinct cui1, cui2, rela from umls.mrrel where cui1 != cui2 and rel = 'CHD' and suppress = 'N' and rela is not null) rel \
  inner join \
 (select distinct cui from umls.mrconso where lat = 'ENG' and ISPREF = 'Y' and TS = 'P' and suppress = 'N' and stt = 'PF' ) con \
    on \
   rel.cui2 = con.cui \
  ); \
CREATE INDEX idx_concept_id  ON ${DB}.child  (concept_id ASC); 
CREATE INDEX idx_attribute_val ON ${DB}.child (attribute_val ASC);   
show warnings \
" >> $LOG 2>&1
if [[ $? -ne 0 ]] ; then  
 exit 1 
fi 


#############################################################################################
#                                                                                           # 
#                                                                                           # 
#                    Crosswalks will be collected from other sources                        # 
#                    mrconso.code will be collected under "crosswallk"                      #
#       Preferred Labels from crosswalks will be collected as Alternative Labels            #
#                                                                                           # 
#                                                                                           # 
#############################################################################################



### NCI
# Collect crosswalk -- codes and preferred labels from NCI

# Collect crosswalk -- Concepts 
# stats:  { env: local, records:~ 3.6M, elapsed:~ 1 min}
echo "Collect crosswalk from NCI into crosswalk table... `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS  -h$HOST -P$PORT  -e " \
DROP TABLE IF EXISTS ${DB}.crosswalk; \
CREATE TABLE ${DB}.crosswalk as ( \
SELECT \
  distinct \
 cui as concept_id, \
 concat(sab, '|', code) attribute_val \
FROM \
  ${DB}.nci_cw) \
; \
show warnings \
" >> $LOG 2>&1
if [[ $? -ne 0 ]] ; then  
 exit 1 
fi 


# Collect crosswalk -- Preferred Labels (as alternative labels) from NCI
# stats:  { env: local, records:~ 2.7M, elapsed:~ 1 min}
echo "Collect crosswalk from NCI into altlabel table... `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS  -h$HOST -P$PORT  -e " \
insert into ${DB}.altlabel \
SELECT \
  distinct \
 cui, \
 str \
FROM \
  ${DB}.nci_cw \
  where \
   ispref = 'Y' and \
   ts = 'P' and \
   stt = 'PF' \
; \
show warnings \
" >> $LOG 2>&1
if [[ $? -ne 0 ]] ; then  
 exit 1 
fi 


### OHDSI 

# Collect crosswalk -- Concepts  from OHDSI source_id = 3
# stats:  { env: local, records:~ 1M, elapsed:~ 10 sec}
echo "Collect crosswalk from OHDSI into crosswalk table... `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS  -h$HOST -P$PORT  -e " \
insert into ${DB}.crosswalk \
SELECT \
  distinct \
 cui, \
 concat(sab,'|',code) \
FROM \
  ${DB}.ohdsi_cw \
; \
show warnings \
" >> $LOG 2>&1
if [[ $? -ne 0 ]] ; then  
 exit 1 
fi 


# Collect crosswalk -- Concept Name (Preferred Label) (as alternative labels) from OHDSI 
# stats:  { env: local, records:~ 1M, elapsed:~ 10 sec}
echo "Collect crosswalk from OHDSI into altlabel table... `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS  -h$HOST -P$PORT  -e " \
insert into ${DB}.altlabel \
SELECT \
  distinct \
 cui, \
 str \
FROM \
  ${DB}.ohdsi_cw \
; \
show warnings \
" >> $LOG 2>&1
if [[ $? -ne 0 ]] ; then  
 exit 1 
fi 


### EVN/ONCOTREE source id 4
# Collect crosswalk -- Concepts  from EVN/ONCOTREE source_id = 4
# stats:  { env: local, records:~ 600, elapsed:~ 1 sec}
echo "Collect crosswalk from EVN/ONCOTREE into crosswalk table... `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS  -h$HOST -P$PORT  -e " \
insert into ${DB}.crosswalk \
SELECT \
  distinct \
 cui, \
 concat(sab, '|', code) \
FROM \
  ${DB}.evn_cw \
; \
show warnings \
" >> $LOG 2>&1
if [[ $? -ne 0 ]] ; then  
 exit 1 
fi 


# Collect crosswalk -- Concept Name (Preferred Label) (as alternative labels) from EVN/ONCOTREE source_id = 4
# stats:  { env: local, records:~ 600, elapsed:~ 1 sec}
echo "Collect crosswalk from EVN/ONCOTREE into altlabel table... `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS  -h$HOST -P$PORT  -e " \
insert into ${DB}.altlabel \
SELECT \
 distinct \
 cui, \
 str \
FROM \
  ${DB}.evn_cw \
; \
show warnings \
" >> $LOG 2>&1
if [[ $? -ne 0 ]] ; then  
 exit 1 
fi 


# Index altlabel post loading crosswalks from all sources
# stats 5 min 
echo "Create altlabel Indices ... `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS  -h$HOST -P$PORT  -e " \
CREATE INDEX idx_concept_id  ON ${DB}.altlabel  (concept_id ASC); \
CREATE FULLTEXT INDEX idx_attribute_val ON ${DB}.altlabel (attribute_val ASC); \
show warnings \
" >> $LOG 2>&1
if [[ $? -ne 0 ]] ; then  
 exit 1 
fi 

# Index crosswalk post loading crosswalks from all sources
# stats 1 min 
echo "Create crosswalk Indices ... `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS  -h$HOST -P$PORT  -e " \
CREATE INDEX idx_concept_id  ON ${DB}.crosswalk  (concept_id ASC); \
CREATE FULLTEXT INDEX idx_attribute_val ON ${DB}.crosswalk (attribute_val ASC); \
show warnings \
" >> $LOG 2>&1
if [[ $? -ne 0 ]] ; then  
 exit 1 
fi 

# Home for collecting rolled up attributes
echo "Create concept_rfs to house rolled up attributes ... `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS  -h$HOST -P$PORT  -e " \
drop table if exists ${DB}.rfs ; \
create table ${DB}.rfs ( \
 concept_id varchar(12), \
 attribute_key varchar (60), \
 attribute_val json); \
show warnings \
" >> $LOG 2>&1
if [[ $? -ne 0 ]] ; then  
 exit 1 
fi 


# Dedupe preflabel in preflabel_unq and index it, then
# rollup in preflabel_rf and index it, finnally collect in concept_rfs
echo "Dedupe preflabel in preflabel_unq and index it, then \
rollup in preflabel_rf and index `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS  -h$HOST -P$PORT  -e " \
drop table if exists ${DB}.preflabel_unq; \
create table ${DB}.preflabel_unq as \
select distinct \
 concept_id, \
 attribute_val \
from \
 ${DB}.preflabel \
; \
CREATE INDEX idx_concept_id  ON ${DB}.preflabel_unq  (concept_id ASC); \
CREATE FULLTEXT INDEX idx_attribute_val ON ${DB}.preflabel_unq (attribute_val ASC); \
drop table if exists ${DB}.preflabel_rf; \
create table ${DB}.preflabel_rf as \
select \
 concept_id, \
 json_arrayagg(${DB}.jclean(attribute_val)) as attribute_val \
from \
 ${DB}.preflabel_unq \
group by \
 concept_id \
 order by \
 concept_id, \
 attribute_val \
; \
CREATE INDEX idx_concept_id  ON ${DB}.preflabel_rf  (concept_id ASC); \
insert into ${DB}.rfs \
select \
 concept_id, \
 'prefLabel', \
 attribute_val \
from \
    ${DB}.preflabel_rf \
; \
show warnings \
" >> $LOG 2>&1
if [[ $? -ne 0 ]] ; then  
 exit 1 
fi



# Dedupe altlabel in altlabel_unq and index it, then
# rollup in altlabel_rf and index, finnally collect in concept_rfs
echo "Dedupe altlabel in altlabel_unq and index it, then \
rollup in altlabel_rf and index `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS  -h$HOST -P$PORT  -e " \
drop table if exists ${DB}.altlabel_unq; \
create table ${DB}.altlabel_unq as \
select distinct \
 concept_id, \
 attribute_val \
from \
 ${DB}.altlabel \
order by \
 concept_id, \
 attribute_val \
 ; \
CREATE INDEX idx_concept_id  ON ${DB}.altlabel_unq  (concept_id ASC); \
CREATE FULLTEXT INDEX idx_attribute_val ON ${DB}.altlabel_unq (attribute_val ASC); \
drop table if exists ${DB}.altlabel_rf; \
create table ${DB}.altlabel_rf as \
select \
 concept_id, \
 json_arrayagg(${DB}.jclean(attribute_val)) as attribute_val \
from \
 ${DB}.altlabel_unq \
group by \
 concept_id \
order by \
 concept_id, \
 attribute_val \
; \
CREATE INDEX idx_concept_id  ON ${DB}.altlabel_rf  (concept_id ASC); \
insert into ${DB}.rfs \
select \
 concept_id, \
 'altLabel', \
 attribute_val \
from \
    ${DB}.altlabel_rf \
; \
show warnings \
" >> $LOG 2>&1
if [[ $? -ne 0 ]] ; then  
 exit 1 
fi




# Dedupe semtype in semtype_unq and index it, then
# rollup in semtype_rf and index, finnally collect in concept_rfs
echo "Dedupe semtype in semtype_unq and index it, then \
rollup in semtype_rf and index `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS  -h$HOST -P$PORT  -e " \
drop table if exists ${DB}.semtype_unq; \
create table ${DB}.semtype_unq as \
select distinct \
 concept_id, \
 attribute_val \
from \
 ${DB}.semtype; \
CREATE INDEX idx_concept_id  ON ${DB}.semtype_unq  (concept_id ASC); \
CREATE INDEX idx_attribute_val ON ${DB}.semtype_unq (attribute_val ASC); \
drop table if exists ${DB}.semtype_rf; \
create table ${DB}.semtype_rf as \
select \
 concept_id, \
 json_arrayagg(attribute_val) as attribute_val \
from \
 ${DB}.semtype_unq \
group by \
 concept_id \
order by \
 concept_id, \
 attribute_val \
; \
CREATE INDEX idx_concept_id  ON ${DB}.semtype_rf (concept_id ASC); \
insert into ${DB}.rfs \
select \
 concept_id, \
 'semType', \
 attribute_val \
from \
    ${DB}.semtype_rf \
; \
show warnings \
" >> $LOG 2>&1
if [[ $? -ne 0 ]] ; then  
 exit 1 
fi


# Dedupe semrel in semrel_unq and index it, then
# rollup in semrel_rf and index, finnally collect in concept_rfs
echo "Dedupe semrel in semrel_unq and index it, then \
rollup in semrel_rf and index `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS  -h$HOST -P$PORT  -e " \
drop table if exists ${DB}.semrel_unq; \
create table ${DB}.semrel_unq as \
select distinct \
 concept_id, \
 attribute_val \
from \
 ${DB}.semrel; \
CREATE INDEX idx_concept_id  ON ${DB}.semrel_unq  (concept_id ASC); \
CREATE INDEX idx_attribute_val ON ${DB}.semrel_unq (attribute_val ASC); \
drop table if exists ${DB}.semrel_rf; \
create table ${DB}.semrel_rf as \
select \
 concept_id, \
 json_arrayagg(attribute_val) as attribute_val \
from \
 ${DB}.semrel_unq \
group by \
 concept_id \
order by \
 concept_id, \
 attribute_val \
 ; \
CREATE INDEX idx_concept_id  ON ${DB}.semrel_rf  (concept_id ASC) \
; \
insert into ${DB}.rfs \
select \
 concept_id, \
 'semRelations', \
 attribute_val \
from \
    ${DB}.semrel_rf \
; \
show warnings \
" >> $LOG 2>&1
if [[ $? -ne 0 ]] ; then  
 exit 1 
fi



# Dedupe dynrel in dynrel_unq and index it, then
# rollup in dynrel_rf and index, finnally collect in concept_rfs
echo "Dedupe dynrel in dynrel_unq and index it, then \
rollup in dynrel_rf and index `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS  -h$HOST -P$PORT  -e " \
drop table if exists ${DB}.dynrel_unq; \
create table ${DB}.dynrel_unq as \
select distinct \
 concept_id, \
 attribute_key, \
 attribute_val \
from \
 ${DB}.dynrel \
; \
CREATE INDEX idx_concept_id  ON ${DB}.dynrel_unq  (concept_id ASC); \
CREATE INDEX idx_attribute_key ON ${DB}.dynrel_unq (attribute_key ASC); \
CREATE INDEX idx_attribute_val ON ${DB}.dynrel_unq (attribute_val ASC); \
drop table if exists ${DB}.dynrel_rf; \
create table ${DB}.dynrel_rf as \
select \
 concept_id, \
 attribute_key, \
 json_arrayagg(attribute_val) as attribute_val \
from \
 ${DB}.dynrel_unq \
group by \
 concept_id, \
 attribute_key \
order by \
 concept_id, \
 attribute_key, \
 attribute_val \
; \
CREATE INDEX idx_concept_id ON ${DB}.dynrel_rf (concept_id ASC); \
CREATE INDEX idx_attribute_key ON ${DB}.dynrel_rf (attribute_key ASC); \
insert into ${DB}.rfs \
select \
 concept_id, \
 attribute_key, \
 attribute_val \
from \
    ${DB}.dynrel_rf \
; \
show warnings \
" >> $LOG 2>&1
if [[ $? -ne 0 ]] ; then  
 exit 1 
fi


# Dedupe parent in parent_unq and index it, then
# rollup in parent_rf and index, finnally collect in concept_rfs
echo "Dedupe parent in parent_unq and index it, then \
rollup in parent_rf and index `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS  -h$HOST -P$PORT  -e " \
drop table if exists ${DB}.parent_unq; \
create table ${DB}.parent_unq as \
select distinct \
 concept_id, \
 attribute_val \
from \
 ${DB}.parent; \
CREATE INDEX idx_concept_id  ON ${DB}.parent_unq  (concept_id ASC); \
CREATE INDEX idx_attribute_val ON ${DB}.parent_unq (attribute_val ASC); \
drop table if exists ${DB}.parent_rf; \
create table ${DB}.parent_rf as \
select \
 concept_id, \
 json_arrayagg(attribute_val) as attribute_val \
from \
 ${DB}.parent_unq \
group by \
 concept_id \
order by \
 concept_id, \
 attribute_val \
 ; \
CREATE INDEX idx_concept_id  ON ${DB}.parent_rf  (concept_id ASC) \
; \
insert into ${DB}.rfs \
select \
 concept_id, \
 'parent', \
 attribute_val \
from \
    ${DB}.parent_rf \
; \
show warnings \
" >> $LOG 2>&1
if [[ $? -ne 0 ]] ; then  
 exit 1 
fi


# Dedupe child in child_unq and index it, then
# rollup in child_rf and index, finnally collect in concept_rfs
echo "Dedupe child in child_unq and index it, then \
rollup in child_rf and index `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS  -h$HOST -P$PORT  -e " \
drop table if exists ${DB}.child_unq; \
create table ${DB}.child_unq as \
select distinct \
 concept_id, \
 attribute_val \
from \
 ${DB}.child; \
CREATE INDEX idx_concept_id  ON ${DB}.child_unq  (concept_id ASC); \
CREATE INDEX idx_attribute_val ON ${DB}.child_unq (attribute_val ASC); \
drop table if exists ${DB}.child_rf; \
create table ${DB}.child_rf as \
select \
 concept_id, \
 json_arrayagg(attribute_val) as attribute_val \
from \
 ${DB}.child_unq \
group by \
 concept_id \
order by \
 concept_id, \
 attribute_val \
 ; \
CREATE INDEX idx_concept_id  ON ${DB}.child_rf  (concept_id ASC); \
insert into ${DB}.rfs \
select \
 concept_id, \
 'child', \
 attribute_val \
from \
    ${DB}.child_rf \
; \
show warnings \
" >> $LOG 2>&1
if [[ $? -ne 0 ]] ; then  
 exit 1 
fi


# Dedupe crosswalk in crosswalk_unq and index it, then
# rollup in crosswalk_rf and index, finnally collect in concept_rfs
echo "Dedupe crosswalk in crosswalk_unq and index it, then \
rollup in crosswalk_rf and index `/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS  -h$HOST -P$PORT  -e " \
drop table if exists ${DB}.crosswalk_unq; \
create table ${DB}.crosswalk_unq as \
select distinct \
 concept_id, \
 attribute_val \
from \
 ${DB}.crosswalk; \
CREATE INDEX idx_concept_id  ON ${DB}.crosswalk_unq  (concept_id ASC); \
CREATE FULLTEXT INDEX idx_attribute_val ON ${DB}.crosswalk_unq (attribute_val ASC); \
drop table if exists ${DB}.crosswalk_rf; \
create table ${DB}.crosswalk_rf as \
select \
 concept_id, \
 json_arrayagg(attribute_val) as attribute_val \
from \
 ${DB}.crosswalk_unq \
group by \
 concept_id \
order by \
 concept_id, \
 attribute_val \
 ; \
CREATE INDEX idx_concept_id  ON ${DB}.crosswalk_rf  (concept_id ASC); \
insert into ${DB}.rfs \
select \
 concept_id, \
 'crosswalk', \
 attribute_val \
from \
    ${DB}.crosswalk_rf \
; \
show warnings \
" >> $LOG 2>&1
if [[ $? -ne 0 ]] ; then  
 exit 1 
fi

# index rfs
echo "Indexing rfs...`/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS  -h$HOST -P$PORT  -e " \
CREATE INDEX idx_concept_id  ON ${DB}.rfs  (concept_id ASC); \
CREATE INDEX idx_attribute_key ON ${DB}.rfs (attribute_key ASC); \
show warnings \
" >> $LOG 2>&1
if [[ $? -ne 0 ]] ; then  
 exit 1 
fi

# Rollup attributes as k,v by concept and create json documents
echo "Rollup attributes as k,v by concept and create json document...`/bin/date`" >> $LOG 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $USER -p$PASS  -h$HOST -P$PORT  -e " \
drop table if exists ${DB}.concept; \
create table ${DB}.concept as \
select \
 concept_id, \
 json_objectagg(attribute_key,attribute_val) as attributes \
from \
 ${DB}.rfs \
group by \
 concept_id \
 ; \
CREATE INDEX idx_concept_id  ON ${DB}.concept (concept_id ASC); \
drop table if exists ${DB}.concepts; \
create table ${DB}.concepts as \
select \
 json_insert(attributes,'$.id',concept_id) as concept \
from \
 ${DB}.concept \
 ; \
SELECT concept from ${DB}.concepts into outfile '${CONCEPTS_FILE}' ; \
show warnings \
" >> $LOG 2>&1
if [[ $? -ne 0 ]] ; then  
 exit 1 
fi
echo "Done....................................................."