#!/usr/bin/env bash
# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


export BUCKET=wiki-staging
export LOGFILE=wikiload.log
export LOGPATH=/tmp/$LOGFILE
>$LOGPATH

# redirect stdout/stderr.
exec 1>$LOGPATH
exec 2>&1

sudo apt-get update
sudo apt-get install -y wget lbzip2

#
# process entities file
#
echo "downloading compressed entity data from cloud storage..."
time gsutil -q cp gs://$BUCKET/dumps.wikimedia.org/wikidatawiki/entities/latest-all.json.bz2 .

echo "uncompressing entity data..."
time lbunzip2 latest-all.json.bz2

echo "uploading uncompressed file to cloud storage..."
time gsutil -q -o GSUtil:parallel_composite_upload_threshold=150M cp latest-all.json gs://$BUCKET/

echo "loading into bq..."
time bq load --field_delimiter="tab" --max_bad_records 1 --replace wikidata.latest_raw gs://$BUCKET/latest-all.json item

QUERY=$(cat <<EOF
  CREATE TEMP FUNCTION parse(item STRING)
  RETURNS STRUCT <
    id STRING
    ,numeric_id INT64
    ,en_label STRING
    ,en_wiki STRING
    ,en_description STRING
    ,ja_label STRING
    ,ja_wiki STRING
    ,ja_description STRING
    ,es_label STRING
    ,es_wiki STRING
    ,es_description STRING
    ,fr_label STRING
    ,fr_wiki STRING
    ,fr_description STRING  
    ,de_label STRING
    ,de_wiki STRING
    ,de_description STRING
    ,type STRING
    ,sitelinks ARRAY<STRUCT<site STRING, title STRING, encoded STRING>>
    ,descriptions ARRAY<STRUCT<language STRING, value STRING>>
    ,labels ARRAY<STRUCT<language STRING, value STRING>>
    ,aliases ARRAY<STRUCT<language STRING, value STRING>>
    ,instance_of ARRAY<STRUCT<numeric_id INT64>>
    ,gender ARRAY<STRUCT<numeric_id INT64>>
    ,date_of_birth ARRAY<STRUCT<time STRING>>
    ,date_of_death ARRAY<STRUCT<time STRING>>
    ,place_of_birth ARRAY<STRUCT<numeric_id INT64>>
    ,country_of_citizenship ARRAY<STRUCT<numeric_id INT64>>
    ,country ARRAY<STRUCT<numeric_id INT64>>
    ,educated_at ARRAY<STRUCT<numeric_id INT64>>
    ,occupation ARRAY<STRUCT<numeric_id INT64>>
    ,instrument ARRAY<STRUCT<numeric_id INT64>>
    ,genre ARRAY<STRUCT<numeric_id INT64>>
    ,industry ARRAY<STRUCT<numeric_id INT64>>
    ,subclass_of ARRAY<STRUCT<numeric_id INT64>>
    ,coordinate_location ARRAY<STRUCT<latitude FLOAT64, longitude FLOAT64>>
    ,iso_3166_alpha3 ARRAY<STRUCT<value STRING>> 
    ,member_of ARRAY<STRUCT<numeric_id INT64>> 
    ,from_fictional_universe ARRAY<STRUCT<numeric_id INT64>> 
  >

  LANGUAGE js AS """
    function wikiEncode(x) {
      return x ? (x.split(' ').join('_')) : null;
    }

    var obj = JSON.parse(item.replace(/,$/, ''));
    sitelinks =[];
    for(var i in obj.sitelinks) {
      sitelinks.push({'site':obj.sitelinks[i].site, 'title':obj.sitelinks[i].title, 'encoded':wikiEncode(obj.sitelinks[i].title)}) 
    }  
    descriptions =[];
    for(var i in obj.descriptions) {
      descriptions.push({'language':obj.descriptions[i].language, 'value':obj.descriptions[i].value}) 
    }
    labels =[];
    for(var i in obj.labels) {
      labels.push({'language':obj.labels[i].language, 'value':obj.labels[i].value}) 
    }
    aliases =[];
    for(var i in obj.aliases) {
      for(var j in obj.aliases[i]) {
        aliases.push({'language':obj.aliases[i][j].language, 'value':obj.aliases[i][j].value}) 
      }
    }

    function snaks(obj, pnumber, name) {
      var snaks = []
      for(var i in obj.claims[pnumber]) {
        if (!obj.claims[pnumber][i].mainsnak.datavalue) continue;
        var claim = {}
        claim[name]=obj.claims[pnumber][i].mainsnak.datavalue.value[name.split('_').join('-')]
        snaks.push(claim) 
      }
      return snaks
    }
    function snaksValue(obj, pnumber, name) {
      var snaks = []
      for(var i in obj.claims[pnumber]) {
        if (!obj.claims[pnumber][i].mainsnak.datavalue) continue;
        var claim = {}
        claim[name]=obj.claims[pnumber][i].mainsnak.datavalue.value
        snaks.push(claim) 
      }
      return snaks
    }
    function snaksLoc(obj, pnumber) {
      var snaks = []
      for(var i in obj.claims[pnumber]) {
        if (!obj.claims[pnumber][i].mainsnak.datavalue) continue;
        var claim = {}
        claim['longitude']=obj.claims[pnumber][i].mainsnak.datavalue.value['longitude']
        claim['latitude']=obj.claims[pnumber][i].mainsnak.datavalue.value['latitude']
        snaks.push(claim) 
      }
      return snaks
    }
    function snaksNum(obj, pnumber) {
      return snaks(obj, pnumber, 'numeric_id');
    }

    return {
      id: obj.id,
      numeric_id: parseInt(obj.id.substr(1)),
      en_wiki: obj.sitelinks ? (obj.sitelinks.enwiki ? wikiEncode(obj.sitelinks.enwiki.title) : null) : null,
      en_label: obj.labels.en ? obj.labels.en.value : null,
      en_description: obj.descriptions.en ? obj.descriptions.en.value : null,
      ja_wiki: obj.sitelinks ? (obj.sitelinks.jawiki ? wikiEncode(obj.sitelinks.jawiki.title) : null) : null,
      ja_label: obj.labels.ja ? obj.labels.ja.value : null,
      ja_description: obj.descriptions.ja ? obj.descriptions.ja.value : null,
      es_wiki: obj.sitelinks ? (obj.sitelinks.eswiki ? wikiEncode(obj.sitelinks.eswiki.title) : null) : null,
      es_label: obj.labels.es ? obj.labels.es.value : null,
      es_description: obj.descriptions.es ? obj.descriptions.es.value : null,
      de_wiki: obj.sitelinks ? (obj.sitelinks.dewiki ? wikiEncode(obj.sitelinks.dewiki.title) : null) : null,
      de_label: obj.labels.de ? obj.labels.de.value : null,
      de_description: obj.descriptions.de ? obj.descriptions.de.value : null,
      type: obj.type,
      labels: labels, 
      descriptions: descriptions,
      sitelinks: sitelinks,
      aliases: aliases,
      instance_of: snaksNum(obj, 'P31'),
      gender: snaksNum(obj, 'P21'),
      date_of_birth: snaks(obj, 'P569', 'time'),
      date_of_death: snaks(obj, 'P569', 'time'),
      place_of_birth: snaksNum(obj, 'P19'),
      country_of_citizenship: snaksNum(obj, 'P27'),
      country: snaksNum(obj, 'P17'),
      educated_at: snaksNum(obj, 'P69'),
      occupation: snaksNum(obj, 'P106'),
      instrument: snaksNum(obj, 'P1303'),
      genre: snaksNum(obj, 'P136'),
      industry: snaksNum(obj, 'P452'),
      subclass_of: snaksNum(obj, 'P279'),
      coordinate_location: snaksLoc(obj, 'P625'),
      iso_3166_alpha3: snaksValue(obj, 'P298', 'value'),
      member_of: snaksNum(obj, 'P463'),
      from_fictional_universe: snaksNum(obj, 'P1080'),
    }
  """;

  CREATE OR REPLACE TABLE \`bigquery-public-data.wikipedia.wikidata\`
  PARTITION BY fake_date
  CLUSTER BY numeric_id
  AS
  SELECT parse(item).*, item, DATE('2000-01-01') fake_date
  FROM \`bigquery-public-data-staging.wikidata.latest_raw\`    
  WHERE LENGTH(item)>10
  AND (
    JSON_EXTRACT_SCALAR(item, '$.sitelinks.enwiki.title') IS NOT NULL
    OR
    JSON_EXTRACT_SCALAR(item, '$.sitelinks.jawiki.title') IS NOT NULL
    OR
    JSON_EXTRACT_SCALAR(item, '$.sitelinks.eswiki.title') IS NOT NULL
    OR
    JSON_EXTRACT_SCALAR(item, '$.labels.en.value') IS NOT NULL
  )
EOF
)

echo "parsing raw data..."
time bq query -q --use_legacy_sql=false "$QUERY"

echo "removing compressed version..."
time gsutil rm gs://$BUCKET/dumps.wikimedia.org/wikidatawiki/entities/latest-all.json.bz2

echo persisting log file...
gsutil cp $LOGPATH gs://$BUCKET/$LOGFILE

echo self-destructing...
gcloud -q compute instances delete $(hostname) --zone \
  $(curl -H Metadata-Flavor:Google http://metadata.google.internal/computeMetadata/v1/instance/zone -s | cut -d/ -f4)
