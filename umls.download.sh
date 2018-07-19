#!/bin/bash

## source: https://download.nlm.nih.gov/rxnorm/terminology_download_script.zip


NIH_USERNAME=$1
NIH_PASSWORD=$2
DOWNLOAD_URL=$3

CAS_LOGIN_URL=https://utslogin.nlm.nih.gov/cas/login
CAS_LOGOUT_URL=https://utslogin.nlm.nih.gov:443/cas/logout
BROWSER_USER_AGENT="Firefox/18.0"
COOKIE_FILE=nih.cookie.txt
NLM_CACERT=nih.gov.crt


if [ $# -ne 3 ]; then echo "         Usage:                                                                                                            "
                      echo "         umls.download.sh nih-username nih-password download_url                                                            "
                      echo "                                                                                                                           "
                      echo "         umls.download.sh nih_username nih_password https://download.nlm.nih.gov/umls/kss/rxnorm/RxNorm_full_current.zip  "
                      echo "         umls.download.sh nih_username nih_password https://download.nlm.nih.gov/umls/kss/rxnorm/RxNorm_weekly_current.zip"
                      echo "         umls.download.sh nih_username nih_password https://download.nlm.nih.gov/umls/kss/2018AA/umls-2018AA-full.zip     "
   exit
fi


echo "Remove old uts auth cookie if exists"
if [ -f $COOKIE_FILE ]; then
    rm $COOKIE_FILE
fi

echo "Go the UTS login page and get the UTS Auth cookie with CAS ticket.."

curl -L -A $BROWSER_USER_AGENT -H Connection:keep-alive -H Expect: -H Accept-Language:en-us --cacert $NLM_CACERT -k -b $COOKIE_FILE  -c $COOKIE_FILE -O $CAS_LOGIN_URL

nonce=`grep "execution" login | awk -F"\"" '{print $6}'`

curl -s -A $BROWSER_USER_AGENT -b $COOKIE_FILE -H Connection:keep-alive -H Expect: -H Accept-Language:en-us -H Referer:$CAS_LOGIN_URL -d "service=$DOWNLOAD_URL&username=$NIH_USERNAME&password=$NIH_PASSWORD&_eventId=submit&submit=LOGIN&execution=$nonce" --cacert $NLM_CACERT -k -c $COOKIE_FILE  -O $CAS_LOGIN_URL 

echo 'Now get the download'
curl -L -A $BROWSER_USER_AGENT -H Connection:keep-alive -H Expect: -H Accept-Language:en-us --cacert $NLM_CACERT -k -b $COOKIE_FILE -O $DOWNLOAD_URL  --silent --output

echo "Now log out.."
curl -s -L -A $BROWSER_USER_AGENT -H Connection:keep-alive -H Expect: -H Accept-Language:en-us --cacert $NLM_CACERT -k -b $COOKIE_FILE $CAS_LOGOUT_URL  --silent --output > logout

echo "cleaning up .."
if [ -f login ]; then
    rm login
fi

if [ -f logout ]; then
    rm logout
fi

if [ -f $COOKIE_FILE ]; then
    rm $COOKIE_FILE
fi
