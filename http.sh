#!env bash

function output
{
  temp=$(mktemp)
  trap  'rm $temp' EXIT
  content=$1
  echo -n $1 | gzip -c > $temp

  echo "HTTP/1.1 200 OK"
  echo "Connection: Keep-Alive"
  echo "Keep-Alive: timeout=5, max=1000"
  echo "Content-Type: text/html; charset=utf-8"
  echo "Content-Encoding: gzip" 
  echo "Content-Length: "`stat -f '%z' ${temp}`
  echo ""
  cat ${temp}
}

function serve
{
  while read line; do 
    line=${line%%$'\r'*}
    if [[ "$line" == "" ]]; then
      content=$(/usr/local/bin/marked -i contents/index.md)
      output "$content"
    fi
  done
}

serve


