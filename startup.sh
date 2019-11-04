#!/usr/bin/env bash

sudo apt-get update
sudo apt-get install -y wget lbzip2

echo downloading...
time gsutil cp gs://wiki-staging/dumps.wikimedia.org/wikidatawiki/entities/latest-all.json.bz2 .

echo uncompressing...
time lbunzip2 latest-all.json.bz2

echo uploading...
time gsutil -o GSUtil:parallel_composite_upload_threshold=150M cp latest-all.json gs://wiki-staging/

echo loading...
time bq load --field_delimiter="tab" --max_bad_records 1 --replace wikidata.latest_raw gs://wiki-staging/latest-all.json item

echo self-destructing...
#gcloud compute instances delete $(hostname) --zone \
  #$(curl -H Metadata-Flavor:Google http://metadata.google.internal/computeMetadata/v1/instance/zone -s | cut -d/ -f4)
