SELECT SUM(views) views, title
FROM `fh-bigquery.wikipedia_v3.pageviews_2019` a
JOIN (
  SELECT DISTINCT en_wiki 
  FROM `mco-wiki-252313.wikidata.wikidata_2019`  
  WHERE EXISTS (SELECT * FROM UNNEST(instance_of) WHERE numeric_id=188784)
  AND en_wiki IS NOT null
) b
ON a.title=b.en_wiki
AND a.wiki='en'
AND DATE(a.datehour) BETWEEN '2019-09-15' AND '2019-09-18'
GROUP BY title
ORDER BY views DESC
LIMIT 10
