#!/usr/bin/env bash

export BUCKET=wiki-staging
export LOG=/tmp/wikiload.log
>$LOG

# redirect stdout/stderr to $LOG.
exec 1>$LOG
exec 2>&1

set -x

sudo apt-get update
sudo apt-get install -y wget lbzip2

echo downloading...
time wget -q https://dumps.wikimedia.org/wikidatawiki/entities/latest-all.json.bz2

echo uncompressing...
time lbunzip2 latest-all.json.bz2

echo uploading...
time gsutil -o GSUtil:parallel_composite_upload_threshold=150M cp latest-all.json gs://$BUCKET/

echo loading...
time bq load --field_delimiter="tab" --max_bad_records 1 --replace wikidata.latest_raw gs://$BUCKET/latest-all.json item

echo persisting log file...
gsutil cp $LOG gs://$BUCKET/$LOG

echo self-destructing...
gcloud -q compute instances delete $(hostname) --zone \
  $(curl -H Metadata-Flavor:Google http://metadata.google.internal/computeMetadata/v1/instance/zone -s | cut -d/ -f4)
