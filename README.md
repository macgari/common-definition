## Common Definitions ETL Utility 


### Overview
This pipeline gathers medical concepts, vocabularies, and terminologies from multiple sources. 
One of the main sources is NIH where concepts come from UMLS and NCI. 
NIH provides data in ths form of binary (files.nlm) files. 
Then NIH provides a system called Metamorphysis which extracts and subsets data into a psv files (files.rrf). 
MetaMorphysis also provides sql scripts to help uploading RRFs (Rich Release Format) to a MySQL server instance.
The typical etl cycle for umls is: umls.nlm -> umls-subset.rrf -> MySQL UMLS database.
The typical etl cycle for nci is: umls.rrf -> (optional) nci.rrf -> MySQL NCI database.
Notice the difference in sources where UMLS provides sources ans .nlm while NCI provides sources as .rrf. 
Due to limitation in design of MetaMorphysis utility, it only accepts (.nlm) files as a source, therefore subsetting is not accomplished during load, however it could be accomplished when querying the nci database.   


### Sources 
 - NIH   -- Must Read    https://www.ncbi.nlm.nih.gov/books/NBK9676/
   - umls
   - nci
 - ohsdi -- Must Read    https://www.ohdsi.org/data-standardization/
 - evn   -- Must Explore https://evn.mskcc.org/evn/tbl/swp?_viewName=home

### Prerequisites
 
 - Nearly 300 GB of storage
 - MySQL server instance, with root access privilege 
   - username and password would need to be updated in nih.sql.sh, ohdsi.sh, and trans.sh scripts

### Scripts

 - umls.nlm.sh -- Downloads and Extracts umls concepts from web
   - umls.download.sh 
   - nih.sql.sh

 - nci.rrf.sh -- Downloads and Extracts nci concepts from web 
   - nci.download.sh				
   - nih.sql.sh

 - ohdsi.sh -- Extracts ohdsi concepts from a manually downloaded archive
   - ohdsi.db.sh
   - ohdsi.indexes.sh
   - ohdsi.constraints.sh _disabled due to errors and its insignificance_

 - evn.sh  -- Downloads and Extracts umls concepts from mskcc intranet
   - evn.download.sh

 - trans.sh -- aggregates and transforms concepts from all sources 

 - load.sh -- Ships concepts and their attributes to cvs repository on SOLR


### Running the pipeline

- Components can be run individually or as a group in parallel
- cdi.sh runs all components in parallel, but prameters need to be loaded into cdi.sh
- Individual components can be run, with arguments, as follows
  - sh umls.nlm.sh nih_username nih_password "https://download.nlm.nih.gov/umls/kss/2018AA/umls-2018AA-full.zip" mysql_username mysql_password mysql_host mysql_port
  - sh nci.rrf.sh nih_username nih_password mysql_username mysql_password mysql_host mysql_port
  - sh ohdsi.sh mysql_username mysql_password mysql_host mysql_port "/path/to/ohdsi/archive.zip"
  - sh evn.sh evn_username evn_password mysql_username mysql_password mysql_host mysql_port
  - sh trans.sh mysql_username mysql_password mysql_host mysql_port trans
  - sh load.sh trans/trans.json


### Notes on Configuration

 Some configurations have dependencies on the environment in which the pipeline is running
  - $MYSQL_HOME needs to be setup correctly in _.profile_, _.bashrc_, _.bash_profile_, etc i.e export MYSQL_HOME=/path/to/mysql/command
  - NIH Account is needed, the same account will be used to pull UMLS and NCI data
  - Depending on the OS, the carriage return needs to be updated for this parameter OSX_SED="s/\\\r\\\n/\\\n/g" in umls.nlm.sh and nci.rrf.sh      


### Links

  - NIH
   
   - UMLS
    - https://download.nlm.nih.gov/umls/kss/2018AA/umls-2018AA-full.zip
    - _update is released twice a year, use new link when available_

   - NCI
    - https://cbiit.cancer.gov/evs-download/download/UTSServlet
    - https://cbiit.cancer.gov/evs-download/download/UMLSServlet
    - _Supposedly will not change, will always point to latest nci_

  - OHDSI
    - http://athena.ohdsi.org/vocabulary/list
    - https://github.com/OHDSI/Vocabulary-v5.0
    - _Manual process, download zip, save to a local path, and use in pipeline_ 

  - EVN
    - https://evn.mskcc.org/evn/tbl/sparql
    - _Concepts are always pulled from the latest graph, however mappings are pulled from a graph that is renamed once a month_



#### _CURLing with SSL_


1) For Mac, this script requires curl with openssl. See the following commands for updating curl with openssl using homebrew (valid as of 11/24/2017):
		> /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
		> brew install --with-openssl curl
		> brew link curl –force



2) Run nih.download.sh with the appropriate nih_username, nih_password and download file URL: (Replace the RxNorm URL example with URL of the file you wish to download.)
		> sh umls.download.sh nih_username nih_password https://download.nlm.nih.gov/umls/kss/rxnorm/RxNorm_full_current.zip
        

----------------------------------------

###### _URLs for frequently downloaded files:_

UMLS (Run nih.download.sh for each file) -
https://download.nlm.nih.gov/umls/kss/2018AA/umls-2018AA-full.zip


U.S. Edition of SNOMED CT -
https://download.nlm.nih.gov/mlb/nihauth/USExt/SnomedCT_USEditionRF2_PRODUCTION_20170901T120000Z.zip


RxNorm Full Monthly Release -
https://download.nlm.nih.gov/umls/kss/rxnorm/RxNorm_full_mmddyyyy.zip
OR
https://download.nlm.nih.gov/umls/kss/rxnorm/RxNorm_full_current.zip

RxNorm Weekly Update - 
https://download.nlm.nih.gov/umls/kss/rxnorm/RxNorm_weekly_mmddyyyy.zip
OR
https://download.nlm.nih.gov/umls/kss/rxnorm/RxNorm_weekly_current.zip



For the full list of download file URLs, visit the downloads page:
https://www.nlm.nih.gov/research/umls/licensedcontent/downloads.html

