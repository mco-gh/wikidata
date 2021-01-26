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

set -eEuo pipefail

SERVICES="pageviews sweep entities load"
PROJECT_ID=bigquery-public-data-staging
IMAGE=wikisync

echo "deploying cloud run services..."
for SERVICE in $SERVICES
do
  gcloud run deploy "$SERVICE" \
    --image "gcr.io/$PROJECT_ID/$IMAGE" \
    --platform "managed" \
    --region "us-central1" \
    --project "${PROJECT_ID}" \
    --concurrency 1 \
    --max-instances 1 \
    --memory 2G \
    --allow-unauthenticated
done

echo "deploying cloud function for object notification..."
gcloud functions deploy handle_new_entity_data --source src --runtime python37 --trigger-resource gs://wiki-staging --trigger-event google.storage.object.finalize --project "${PROJECT_ID}"
