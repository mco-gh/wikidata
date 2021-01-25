-- Copyright 2020 Google LLC
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--      http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

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
