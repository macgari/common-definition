#!/bin/sh -f

if [ $# -ne 3 ]; then echo "Usage : ./ohsdi.sh ohsdi_database ohsdi_username ohsdi_password /path/to/ohsdi/csv/files/ "  
 exit 
fi
DB=$1
USERNAME=$2
PATH=$3


/usr/local/bin/psql -d $DB -U $USERNAME -f ./ohdsi.db.sql
if [ $? -ne 0 ]; then
    echo "Error creating db tables" 1>&2
    exit
fi


/usr/local/bin/psql -d $DB -U $USERNAME -c " \
COPY DRUG_STRENGTH FROM '$PATH/DRUG_STRENGTH.csv' WITH DELIMITER E'\t' CSV HEADER QUOTE E'\b' ; \
COPY CONCEPT FROM '$PATH/CONCEPT.csv' WITH DELIMITER E'\t' CSV HEADER QUOTE E'\b' ; \
COPY CONCEPT_RELATIONSHIP FROM '$PATH/CONCEPT_RELATIONSHIP.csv' WITH DELIMITER E'\t' CSV HEADER QUOTE E'\b' ; \
COPY CONCEPT_ANCESTOR FROM '$PATH/CONCEPT_ANCESTOR.csv' WITH DELIMITER E'\t' CSV HEADER QUOTE E'\b' ; \
COPY CONCEPT_SYNONYM FROM '$PATH/CONCEPT_SYNONYM.csv' WITH DELIMITER E'\t' CSV HEADER QUOTE E'\b' ; \
COPY VOCABULARY FROM '$PATH/VOCABULARY.csv' WITH DELIMITER E'\t' CSV HEADER QUOTE E'\b' ; \
COPY RELATIONSHIP FROM '$PATH/RELATIONSHIP.csv' WITH DELIMITER E'\t' CSV HEADER QUOTE E'\b' ; \
COPY CONCEPT_CLASS FROM '$PATH/CONCEPT_CLASS.csv' WITH DELIMITER E'\t' CSV HEADER QUOTE E'\b' ; \
COPY DOMAIN FROM '$PATH/DOMAIN.csv' WITH DELIMITER E'\t' CSV HEADER QUOTE E'\b' ;"

/usr/local/bin/psql -d $DB -U $USERNAME -f ./ohdsi.indexes.sql
if [ $? -ne 0 ]; then
    echo "Error creating db indexes" 1>&2
    exit
fi

#Some errors, and not realy neede
#/usr/local/bin/psql -d $DB -U $USERNAME -f ./ohdsi.constraints.sql
# i#     echo "Error creating db constraints" 1>&2
f [ $? -ne 0 ]; then
#     exit
# fi

# psql:./ohdsi.constraints.sql:71: ERROR:  insert or update on table "concept_relationship" violates foreign key constraint "fpk_concept_relationship_c_1"
# DETAIL:  Key (concept_id_1)=(2108888) is not present in table "concept".
# psql:./ohdsi.constraints.sql:73: ERROR:  insert or update on table "concept_relationship" violates foreign key constraint "fpk_concept_relationship_c_2"
# DETAIL:  Key (concept_id_2)=(2108888) is not present in table "concept".
# psql:./ohdsi.constraints.sql:81: ERROR:  insert or update on table "concept_synonym" violates foreign key constraint "fpk_concept_synonym_concept"
# DETAIL:  Key (concept_id)=(2100652) is not present in table "concept".
# psql:./ohdsi.constraints.sql:83: ERROR:  insert or update on table "concept_ancestor" violates foreign key constraint "fpk_concept_ancestor_concept_1"
# DETAIL:  Key (ancestor_concept_id)=(2100652) is not present in table "concept".
# psql:./ohdsi.constraints.sql:85: ERROR:  insert or update on table "concept_ancestor" violates foreign key constraint "fpk_concept_ancestor_concept_2"
# DETAIL:  Key (descendant_concept_id)=(2100652) is not present in table "concept".
