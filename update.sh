
echo "2019 11 18" | while read YEAR MONTH DAY
do
  echo "inserting data from GCS to BQ for $YEAR-$MONTH-$DAY..."
  QUERY=$(cat <<EOF
  INSERT INTO \`bigquery-public-data.wikipedia.pageviews_$YEAR\`
   (datehour TIMESTAMP, wiki STRING, title STRING, views INT64)
   AS SELECT datehour, wiki, SUBSTR(title, 0, 300) title, views
   FROM \`bigquery-public-data.wikipedia.view_parsed\` t1
   WHERE BYTE_LENGTH(wiki)+ BYTE_LENGTH(title) < 1024
   AND BYTE_LENGTH(title) < 300
   AND EXTRACT(YEAR FROM datehour)=$YEAR
   AND EXTRACT(MONTH FROM datehour)=$MONTH
   AND EXTRACT(DAY FROM datehour)=$DAY'
EOF
)
   echo bq query $QUERY
done
