## Common Definitions ETL Utility 


### Overview
This pipeline gathers and combines health/medical concepts and terminologies from multiple sources. 
One of the main sources is NIH where concepts come from UMLS and NCI. 
NIH provides data in ths form of binary (files.nlm) files. 
Then NIH provides a system called Metamorphysis which extracts and subsets data into a psv files (files.rrf). 
MetaMorphysis also provides sql scripts to help uploading RRFs (Rich Release Format) to a MySQL server instance.
The typical etl cycle for umls is: umls.nlm -> umls-subset.rrf -> MySQL UMLS database.
The typical etl cycle for nci is: umls.rrf -> (optional) nci.rrf -> MySQL NCI database.
Notice the difference in sources where UMLS provides sources ans .nlm while NCI provides sources as .rrf. 
Due to limitation in design of MetaMorphysis utility, it only accepts (.nlm) files as a source, therefore subsetting is not accomplished during load, however it could be accomplished when querying the nci database.  



### Sources 
 - NIH
   - umls -- functional
   - nci -- functional
 - ohsdi -- functional 
 - msk ontology -- TopBraid -- in spike




### Prerequisits
 
 - 250GB of disk space
 - MySQL server instance
   - username and password would need to be updated in nih.sql.sh, ohdsi.sh scripts



### Scripts

 There are two main scripts [umls.nlm.sh, and nci.rrf.sh] that process [ umls, and nci ] resplectively. 
 The two scripts could optionally be run from nih.sh. The two main ecripts call sub-scripts are indicated below. All scripts need arguments. 
 Details are listed in each script. nih.sql.sh script is a sub-script for both of main script and called using different arguments.  
 
 - nci.rrf.sh
   - nci.download.sh				
   - nih.sql.sh
 
 - umls.nlm.sh
   - umls.download.sh	
   - nih.sql.sh

 - ohdsi.sh
   - ohdsi.db.sh
   - ohdsi.indexes.sh
   - ohdsi.constraints.sh _disabled due to errors and its insignificance_


### Running the pipeline

- Different components can run individually or as a group in parallel
- cdi.sh runs all components in parallel, but prameters need to be loaded
- Individual components can be run, with arguments, as follows
  - sh umls.nlm.sh nih_username nih_password "https://download.nlm.nih.gov/umls/kss/2017AB/umls-2017AB-full.zip" mysql_username mysql_password
  - sh nci.rrf.sh nih_username nih_password mysql_username mysql_password
  - sh ohdsi.sh mysql_username mysql_password "/path/to/ohdsi/archive.zip"



### Configurations notes

 Some configurations have dependencies on the environment in which the pipeline is running
  - NIH Account is needed, the same account will be used to pull UMLS and NCI data
  - Depending on the OS, in umls.nlm.sh and nci.rrf.sh, the criage return needs to be updated for this parameter OSX_SED="s/\\\r\\\n/\\\n/g"      


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
https://download.nlm.nih.gov/umls/kss/2017AB/umls-2017AB-full.zip


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
https://nih.nih.gov/research/umls/licensedcontent/downloads.html

