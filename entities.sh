# if today is Sunday, arrange to get compressed wikidata file.
if [[ $(date +%u) -eq 7 ]]
then
  export SFILE SSIZE DFILE DSIZE
  read SFILE SSIZE \
    <<<$(wget -nv --spider -S -r -A ".gz" -I $SRC_DATA_PATH $SRC_DATA_URL 2>&1 |
         awk 'function base(file, a, n) {n = split(file,a,"/"); return a[n]} \
              $1 == "Content-Length:" {len=$2} $3 == "URL:" {print base($4), len}')
  read DFILE DSIZE \
    <<<$(gsutil ls -l -r $DST_DATA_URL |
         awk 'function base(file, a, n) {n = split(file,a,"/"); return a[n]} \
              $1 != "TOTAL:" {print base($3), $1}')
  if [ "$SFILE" != "$DFILE" -o "$SSIZE" != "$DSIZE" ]
  then
    echo $SRC_DATA_URL
  fi
fi
