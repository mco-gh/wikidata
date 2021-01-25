#!/bin/python
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

from google.cloud import bigquery
SCHEMA = [bigquery.SchemaField('line', 'STRING')]
bq_client = bigquery.Client(project='bigquery-public-data-staging')
table_ref = bq_client.dataset('wikipedia_pipeline').table('view_gcs')
table = bigquery.Table(table_ref, schema=SCHEMA)
extconfig = bigquery.ExternalConfig('CSV')
extconfig.schema = SCHEMA
extconfig.options.field_delimiter = u'\u00ff'
extconfig.options.quote_character = ''
extconfig.compression = 'GZIP'
extconfig.options.allow_jagged_rows = False
extconfig.options.allow_quoted_newlines = False
extconfig.max_bad_records = 10000000
extconfig.source_uris=[
  "gs://wiki-staging/dumps.wikimedia.org/other/pageviews/*"
]
table.external_data_configuration = extconfig
bq_client.create_table(table)
