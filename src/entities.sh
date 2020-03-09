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

# Independent variables
BUCKET=wiki-staging
DOMAIN=dumps.wikimedia.org
SRC_BASE=https://$DOMAIN
DST_BASE=gs://$BUCKET
SRC_DATA_PATH=wikidatawiki/entities/latest-all.json.bz2
DST_DATA_PATH=$DOMAIN/$SRC_DATA_PATH
SRC_DATA_URL=$SRC_BASE/$SRC_DATA_PATH
DST_DATA_URL=$DST_BASE/$DST_DATA_PATH

HEAD="$(cat <<EOF
HTTP/1.1 200 OK
Connection: keep-alive\r\n\r\n
EOF
)"

if [ -z ${K_SERVICE+x} ]
then
  EOL="\n"
else
  EOL="\r\n"
  echo -en "$HEAD" 
fi

# Get name and size of latest wikidata file on website.
read SFILE SSIZE \
  <<<$(wget -nv --spider -S -r -A ".gz" -I $SRC_DATA_PATH $SRC_DATA_URL 2>&1 |
       awk 'function base(file, a, n) {n = split(file,a,"/"); return a[n]} \
            $1 == "Content-Length:" {len=$2} $3 == "URL:" {print base($4), len}')

# Get name and size of latest wikidata file copy we have in Cloud Storage.
read DFILE DSIZE \
  <<<$(gsutil ls -l -r $DST_DATA_URL |
       awk 'function base(file, a, n) {n = split(file,a,"/"); return a[n]} \
            $1 != "TOTAL:" {print base($3), $1}')

echo -en "TsvHttpData-1.0$EOL"
# If new file available, display it for further processing.
if [ "$SFILE" != "$DFILE" -o "$SSIZE" != "$DSIZE" ]
then
  echo -en "$SRC_DATA_URL$EOL"
fi
