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


if [ "$1" = "" -o "$2" = "" -o "$3" = "" ]
then
 echo "usage: $0 year month day"
 exit 1
fi

YEAR=$1
MONTH=$2
DAY=$3

QUERY=$(cat <<EOF
  CREATE TABLE IF NOT EXISTS \`bigquery-public-data.wikipedia.pageviews_$YEAR\`
    (datehour TIMESTAMP, wiki STRING, title STRING, views INT64)
    PARTITION BY DATE(datehour)
    CLUSTER BY wiki, title
    OPTIONS(
      description = 'Wikipedia pageviews from http://dumps.wikimedia.your.org/other/pageviews/, partitioned by date, clustered by (wiki, title)',
      require_partition_filter = true
    )
EOF
)

echo "creating table (if necessary) for $YEAR..."
bq query -q --use_legacy_sql=false "$QUERY"

QUERY=$(cat <<EOF
  INSERT INTO \`bigquery-public-data.wikipedia.pageviews_$YEAR\`
  WITH already_loaded as ( 
    SELECT DISTINCT datehour FROM \`bigquery-public-data.wikipedia.pageviews_$YEAR\`
    WHERE datehour >= '$YEAR-$MONTH-$DAY')
  SELECT datehour, wiki, SUBSTR(title, 0, 300) title, views
  FROM \`bigquery-public-data-staging.wikipedia_pipeline.view_parsed\` t1
  WHERE BYTE_LENGTH(wiki)+ BYTE_LENGTH(title) < 1024
  AND BYTE_LENGTH(title) < 300
  AND EXTRACT(YEAR FROM datehour)=$YEAR
  AND EXTRACT(MONTH FROM datehour)=$MONTH
  AND EXTRACT(DAY FROM datehour)=$DAY
  AND NOT EXISTS (SELECT * FROM already_loaded t2 WHERE t2.datehour = t1.datehour)
EOF
)

echo "inserting data from GCS to BQ for $YEAR-$MONTH-$DAY..."
bq query -q --use_legacy_sql=false "$QUERY"
