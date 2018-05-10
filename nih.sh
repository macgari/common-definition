#!/bin/sh -f

######################################################
##### Home for processing umls and nci pipelines #####
#####  - runs umls and nci pipelines in parallel #####
######################################################


if [ $# -lt 3 ]; then echo "         Usage:                                                                                                            " 
                      echo "         ./nih.sh nih-username nih-password umls-download_URL                                                            "
                      echo "                                                                                                                           "  
		              echo "         ./nih.sh nih_username nih_password https://download.nlm.nih.gov/umls/kss/rxnorm/RxNorm_full_current.zip  "
                      echo "         ./nih.sh nih_username nih_password https://download.nlm.nih.gov/umls/kss/rxnorm/RxNorm_weekly_current.zip"
                      echo "         ./nih.sh nih_username nih_password https://download.nlm.nih.gov/umls/kss/2017AB/umls-2017AB-full.zip     " 
   exit
fi


echo "Processing UMLS..."
sh umls.nlm.sh $1 $2 $3 &


echo "Processing NCI..."
sh nci.rrf.sh $1 $2 &

wait