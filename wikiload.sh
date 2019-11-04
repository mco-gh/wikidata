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

# MAKE THIS VM PREEMPTIBLE!
# and generalize startup script
echo "creating VM...$EOL"

gcloud beta compute instances create $VMNAME \
  --zone=$ZONE \
  --machine-type=m1-ultramem-80 \
  --subnet=default \
  --network-tier=PREMIUM \
  --no-restart-on-failure \
  --maintenance-policy=TERMINATE \
  --scopes=https://www.googleapis.com/auth/cloud-platform \
  --image=debian-9-drawfork-v20191004 \
  --image-project=eip-images \
  --boot-disk-size=1000GB \
  --boot-disk-type=pd-ssd \
  --boot-disk-device-name=wikiload \
  --reservation-affinity=any \
  --metadata-from-file startup-script=startup.sh
  #--preemptible

echo "DONE.$EOL"
