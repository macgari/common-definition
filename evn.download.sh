#!/bin/bash

EVN_USERNAME=$1
EVN_PASSWORD=$2
if [ $# -ne 2 ]; then echo "  Usage:  use MSK-EVN authentication              "
                      echo "      evn.download.sh evn-username evn-password   "
   exit
fi

ROOT=$(pwd)
EVN_DIR=$ROOT/evn
EVN_HEADERS="Accept: text/csv"
EVN_COOKIE=$EVN_DIR/evn_cookie
EVN_URL=https://evn.mskcc.org/evn/tbl/
EVN_JSC=https://evn.mskcc.org/evn/j_security_check
SPRQL_URL=https://evn.mskcc.org/evn/tbl/sparql
CONCEPT_TABLE=$EVN_DIR/concept.csv
MAPPING_TABLE=$EVN_DIR/mapping.csv
QUERY_RESULT=$EVN_DIR/result

#there is a chance this link might need to be updated every now and then
ONTOLOGY_GRAPH="urn:x-evn-master:oncotree_2017_11_01_to_msk_ontology"

CONCEPT_SED="s/http:\/\/data.mskcc.org\/ontologies\/api\/concept\///g"
ONTOLOGY_SED="s/http:\/\/data.mskcc.org\/ontologies\/oncotree\///g"

LATEST_GRAPH_QUERY="SELECT ?latest_oncotree_graph_uri 
WHERE {
  GRAPH <urn:x-evn-master:oncotree_version> {
    <http://data.mskcc.org/ontologies/oncotree_version/oncotree_latest_stable> 
    <http://data.mskcc.org/ontologies/oncotree_version/graph_uri> 
    ?latest_oncotree_graph_uri
  }
}"

curl  $EVN_URL  -s -c $EVN_COOKIE --output /dev/null     
curl  $EVN_JSC -s -L -b $EVN_COOKIE -c $EVN_COOKIE  --data "j_username=$EVN_USERNAME&j_password=$EVN_PASSWORD&login=LOGIN" --output /dev/null
LATEST_GRAPH=$(echo $(curl $SPRQL_URL -s -b $EVN_COOKIE -H "$EVN_HEADERS" --data "query=$LATEST_GRAPH_QUERY") |  tr -d '\r' | cut -d ' ' -f2)

CONCEPT_QUERY="prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>
prefix skos: <http://www.w3.org/2004/02/skos/core#> 
prefix onc: <http://data.mskcc.org/ontologies/oncotree/>
SELECT ?concept_id ?prefLabel ?altLabel  ?broader ?narrower_concept_id 
WHERE {
	GRAPH <$LATEST_GRAPH> {
		?concept_id rdf:type <http://data.mskcc.org/ontologies/oncotree/Oncotree_Concept>;
                                    skos:prefLabel ?prefLabel;
                                    skos:notation ?altLabel;
                                    skos:broader ?broader.
                ?narrower_concept_id  skos:broader ?concept_id
	}
}"

MAPPING_QUERY="prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>
prefix skos: <http://www.w3.org/2004/02/skos/core#> 
prefix onc: <http://data.mskcc.org/ontologies/oncotree/>
prefix crosswalk: <http://topbraid.org/crosswalk#>
SELECT ?MSK_ids ?Oncotree_id
WHERE {
	GRAPH <$ONTOLOGY_GRAPH> {
             ?MSK_ids crosswalk:closeMatch ?Oncotree_id
	}
}"

rm -rf ${CONCEPT_TABLE}
curl $SPRQL_URL -s -b $EVN_COOKIE  -H "$EVN_HEADERS" --data "query=$CONCEPT_QUERY" --output ${CONCEPT_TABLE}tmp
sed -e "$ONTOLOGY_SED" ${CONCEPT_TABLE}tmp > $CONCEPT_TABLE
rm -rf ${CONCEPT_TABLE}tmp
echo "Extracted: $(($(echo $(cat $CONCEPT_TABLE | wc -l))-1)) Concepts From EVN"


rm -rf ${MAPPING_TABLE}
curl $SPRQL_URL -s -b $EVN_COOKIE  -H "$EVN_HEADERS" --data "query=$MAPPING_QUERY" --output ${MAPPING_TABLE}tmp
sed -e "$CONCEPT_SED" -e "$ONTOLOGY_SED" ${MAPPING_TABLE}tmp > $MAPPING_TABLE
rm -rf ${MAPPING_TABLE}tmp
echo "Extracted: $(($(echo $(cat $MAPPING_TABLE | wc -l))-1)) Mappings From EVN"
