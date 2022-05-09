from google.cloud import bigquery

tables = {
    "bands":          (5741069, 215380),
    "writers":        (36180, 482980),
    "born":           (19,),
    "worked":         (108,),
    "actors":         (33999,),
    "singers":        (177220,),
    "athlete":        (2066131,),
    "alumni":         (508719,),
    "politicians":    (82955,),
    "businesspeople": (43845,),
    "scientists":     (901,),
    "artists":        (483501,),
    "composers":      (36834,),
    "inventors":      (205375,),
    "activists":      (15253558,),
    "comedians":      (245068,),
}

def bld_query(category, where):
   return f"""
CREATE OR REPLACE TABLE `bigquery-public-data.wikipedia.table_{category}`
(datehour TIMESTAMP, title STRING, views INT64)
PARTITION BY DATE(datehour)
CLUSTER BY title
AS
  SELECT datehour, title, SUM(views) views
  FROM `bigquery-public-data.wikipedia.pageviews_*` a
  JOIN (
    SELECT DISTINCT en_wiki
    FROM `bigquery-public-data.wikipedia.wikidata`
    WHERE EXISTS (SELECT * FROM UNNEST(instance_of) WHERE {where})
    AND en_wiki IS NOT null
  ) b
ON a.title=b.en_wiki
AND a.wiki='en'
AND DATE(a.datehour) BETWEEN '2015-01-01' AND '2021-12-31'
GROUP BY datehour, title"""

client = bigquery.Client()
for (category, ids) in tables.items():
    first = True
    where = ""
    for id in ids:
        if not first:
            where = where + " or "
        where = where + f"numeric_id={id}"
        first = False
    query = bld_query(category, where)
    print(f"building {category} table")
    query_job = client.query(query)
    print(category, query_job.job_id)
