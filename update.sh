
if [ "$1" = "" -o "$2" = "" -o "$3" = "" ]
then
 echo "usage: $0 year month day"
 exit 1
fi

YEAR=$1
MONTH=$2
DAY=$3
echo "inserting data from GCS to BQ for $YEAR-$MONTH-$DAY..."
QUERY=$(cat <<EOF
  INSERT INTO \`bigquery-public-data.wikipedia.pageviews_$YEAR\`
  SELECT datehour, wiki, SUBSTR(title, 0, 300) title, views
  FROM \`bigquery-public-data-staging.wikipedia_pipeline.view_parsed\`
  WHERE BYTE_LENGTH(wiki)+ BYTE_LENGTH(title) < 1024
  AND BYTE_LENGTH(title) < 300
  AND EXTRACT(YEAR FROM datehour)=$YEAR
  AND EXTRACT(MONTH FROM datehour)=$MONTH
  AND EXTRACT(DAY FROM datehour)=$DAY
EOF
)
bq query -q --use_legacy_sql=false $QUERY
