#!/bin/python
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
