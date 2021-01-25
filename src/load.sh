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

VMNAME=wikiload
PROJECT=bigquery-public-data-staging
ZONE=us-central1-b
SCOPES="https://www.googleapis.com/auth/cloud-platform"

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
  gcloud config set account 598876566128-compute@developer.gserviceaccount.com
  gcloud config set project $PROJECT
fi

echo -en "creating VM to migrate wikidata...EOL"
gcloud beta compute instances create $VMNAME \
  --zone=$ZONE \
  --machine-type=m1-ultramem-80 \
  --subnet=default \
  --network-tier=PREMIUM \
  --no-restart-on-failure \
  --maintenance-policy=TERMINATE \
  --scopes=$SCOPES \
  --image=projects/debian-cloud/global/images/debian-10-buster-v20191115 \
  --image-project=debian-cloud \
  --boot-disk-size=2000GB \
  --boot-disk-type=pd-ssd \
  --boot-disk-device-name=wikiload \
  --reservation-affinity=any \
  --metadata-from-file startup-script=startup.sh

echo -en "DONE.$EOL"
