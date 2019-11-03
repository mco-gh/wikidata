#!/usr/bin/env bash

# Copyright 2019 Google LLC
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

set -eEuo pipefail

if [ -z ${K_SERVICE+x} ]
then
  EOL="\n"
else
  EOL="\r\n"
fi
USAGE="$0 [all|year|month|day]"
WINDOW="${1:-day}"
PROJECT=bigquery-public-data-staging
BUCKET=wiki-staging
DOMAIN=dumps.wikimedia.org
SRC_BASE=https://$DOMAIN
DST_BASE=gs://$BUCKET
SRC_DATA_PATH=wikidatawiki/entities/latest-all.json.bz2
DST_DATA_PATH=$DOMAIN/$SRC_DATA_PATH
SRC_VIEW_PATH=other/pageviews
DST_VIEW_PATH=$DOMAIN/$SRC_VIEW_PATH

SRC_DATA_URL=$SRC_BASE/$SRC_DATA_PATH
DST_DATA_URL=$DST_BASE/$DST_DATA_PATH
SRC_VIEW_URL=$SRC_BASE/$SRC_VIEW_PATH
DST_VIEW_URL=$DST_BASE/$DST_VIEW_PATH

HEAD="$(cat <<EOF
HTTP/1.1 200 OK
Connection: keep-alive\r\n\r\n
EOF
)"


TODAY=$(date '+%s')
YYYY=$(date --date=@$TODAY +%Y)
MM=$(date --date=@$TODAY +%m)
DD=$(date --date=@$TODAY +%d)

if [ ! -z ${K_SERVICE+x} ]
then
  echo -en "$HEAD" 
fi
echo -en "TsvHttpData-1.0$EOL"

# if today is Sunday, arrange to get compressed wikidata file.
if [[ $(date +%u) -eq 7 ]]
then
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
    echo $SRC_DATA_URL
  fi
fi
