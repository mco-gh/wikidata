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

BUCKET=wiki-staging
DOMAIN=dumps.wikimedia.org
DST_BASE=gs://$BUCKET
DST_DATA_PATH=$DOMAIN/$SRC_DATA_PATH
DST_DATA_URL=$DST_BASE/$DST_DATA_PATH
VMNAME=wikiload
ZONE=us-central1-c
SCOPES="https://www.googleapis.com/auth/compute,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/trace.append,https://www.googleapis.com/auth/devstorage.read_only"

HEAD="$(cat <<EOF
HTTP/1.1 200 OK
Connection: keep-alive\r\n\r\n
EOF
)"

if [ ! -z ${K_SERVICE+x} ]
then
  echo -en "$HEAD" 
fi

echo "creating VM...$EOL"
gcloud compute instances create $VMNAME \
  --zone=$ZONE \
  --image-family=ubuntu-1804-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=200GB \
  --scopes=$SCOPES \
  --metadata-from-file startup-script=startup.sh
echo "DONE.$EOL"
