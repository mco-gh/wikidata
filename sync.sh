#!/bin/bash

set -eEuo pipefail

USAGE="$0 all|year|month"
WINDOW=$1
SUFFIX=

PROJECT=bigquery-public-data-staging
BUCKET=wiki-staging
DOMAIN=dumps.wikimedia.org
SRC_BASE=https://$DOMAIN
DST_BASE=gs://$BUCKET
SRC_DATA_PATH=wikidatawiki/entities/latest-all.json.bz2
DST_DATA_PATH=$DOMAIN/$SRC_DATA_PATH
SRC_VIEW_PATH=other/pageviews
DST_VIEW_PATH=$DOMAIN/$SRC_VIEW_PATH
FILE_LIST=file-list.tsv

SRC_DATA_URL=$SRC_BASE/$SRC_DATA_PATH
DST_DATA_URL=$DST_BASE/$DST_DATA_PATH
SRC_VIEW_URL=$SRC_BASE/$SRC_VIEW_PATH
DST_VIEW_URL=$DST_BASE/$DST_VIEW_PATH
FILE_LIST_URL=gs://$BUCKET/$FILE_LIST

YESTERDAY=$(($(date '+%s') - 86400))
YYYY=$(date -r $YESTERDAY +%Y)
MM=$(date -r $YESTERDAY +%m)
DD=$(date -r $YESTERDAY +%d)
if   [ "$WINDOW" = "all" ];   then SUFFIX=
elif [ "$WINDOW" = "year" ];  then SUFFIX=/$YYYY
elif [ "$WINDOW" = "month" ]; then SUFFIX=/$YYYY/$YYYY-$MM
else
  echo $USAGE
  exit 1
fi

gcloud config set project $PROJECT

echo "TsvHttpData-1.0" >$FILE_LIST

# if today is Sunday, arrange to get compressed wikidata file.
if [[ $(date +%u) -eq 7 ]]
then
  export SFILE SSIZE DFILE DSIZE
  read SFILE SSIZE \
    <<<$(wget -nv --spider -S -r -A ".gz" -I $SRC_DATA_PATH $SRC_DATA_URL 2>&1 |
         awk 'function base(file, a, n) {n = split(file,a,"/"); return a[n]} \
              $1 == "Content-Length:" {len=$2} $3 == "URL:" {print base($4), len}')
  read DFILE DSIZE \
    <<<$(gsutil ls -l -r $DST_DATA_URL |
         awk 'function base(file, a, n) {n = split(file,a,"/"); return a[n]} \
              $1 != "TOTAL:" {print base($3), $1}')
  if [ "$SFILE" != "$DFILE" -o "$SSIZE" != "$DSIZE" ]
  then
    echo $SRC_DATA_URL >>$FILE_LIST
  fi
fi

# Assemble list of every pageview log file and size on website.
wget -nv --spider -S -r -A ".gz" -I $SRC_VIEW_PATH$SUFFIX $SRC_VIEW_URL$SUFFIX 2>&1 |
  awk 'function base(file, a, n) {n = split(file,a,"/"); return a[n]} \
       $1 == "Content-Length:" {len=$2} $3 == "URL:" {print base($4), len}' >src-files

sort src-files >src-files.txt

# Assemble list of every pageview log file and size in cloud storage.
gsutil ls -l -r $DST_VIEW_URL$SUFFIX | grep -v ":$" |
  awk 'function base(file, a, n) {n = split(file,a,"/"); return a[n]} \
       $1 != "TOTAL:" {print base($3), $1}' | sort >dst-files.txt

# One-sided diff - every file that doesn't exist or match size in cloud storage.
comm -23 src-files.txt dst-files.txt |
while read FILE SIZE
do
  DIR=`echo $FILE | awk '{y=substr($1,11,4);m=substr($1,15,2); printf("%s/%s-%s",y,y,m)}'`
  echo $SRC_VIEW_URL/$DIR/$FILE >>$FILE_LIST
done

gsutil cp $FILE_LIST $FILE_LIST_URL
gsutil acl set -r public-read $FILE_LIST_URL
