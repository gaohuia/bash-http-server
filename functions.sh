declare -A STATUS_CODE

STATUS_CODE['200']="OK"
STATUS_CODE['400']="Bad Request"
STATUS_CODE['404']="Not Found"
STATUS_CODE['405']="Method Not Allowed"

GZIP=1

StatusCode=200
ResponseHeaders=()
HeaderOut=0

function SetStatusCode
{
  StatusCode=$1
}

function ResetHeaders
{
  ResponseHeaders=()
}

function AddHeader
{
  ResponseHeaders=("${ResponseHeaders[@]}" "$1")
}

function SetHeader
{
  newheaders=()
  
  RE="([^:]*)\:(.*)$"
  if [[ "$1" =~ $RE ]]; then
    name="${BASH_REMATCH[1]}"
    value="${BASH_REMATCH[2]}"

    for header in "${ResponseHeaders[@]}"; do
      if [[ ! "${header}" =~ $RE ]] || [[ "${BASH_REMATCH[1]}" != "${name}" ]]; then
        newheaders=( "${newheaders[@]}" "$header" )
      fi
    done

    newheaders=( "${newheaders[@]}" "${name}:${value}" )
    ResponseHeaders=( "${newheaders[@]}" )
  fi
}

function HasHeader
{
  name="$1"
  RE="([^:]*)\:(.*)$"

  for header in "${ResponseHeaders[@]}"; do
    if [[ ! "${header}" =~ $RE ]] || [[ "${BASH_REMATCH[1]}" == "${name}" ]]; then
      return 0
    fi
  done

  return 1
}

function GetHeader
{
  name="$1"
  RE="([^:]*)\:(.*)$"

  for header in "${ResponseHeaders[@]}"; do
    if [[ ! "${header}" =~ $RE ]] || [[ "${BASH_REMATCH[1]}" == "${name}" ]]; then
      echo "${BASH_REMATCH[2]}"
    fi
  done
}

function SetDefaultHeads
{
  heads=(
    "Server: Bash Http Server"
    "Date: `date -u +'%a, %d %b %Y %H:%M:%S GMT'`"
    "Connection: Keep-Alive"
    "Keep-Alive: timeout=5, max=1000"
  )

  for head in "${heads[@]}"; do
    SetHeader "${head}"
  done
}

function FlushHeaders
{
  HeaderOut=1
  echo "HTTP/1.1 ${StatusCode} ${STATUS_CODE[$StatusCode]}"

  for head in "${ResponseHeaders[@]}"; do
    echo "${head}"
  done

  echo ""
}

function output
{
  temp=$(mktemp)
  trap  'rm $temp' EXIT

  content=$1

  

  if ! HasHeader 'Content-Type' ; then
    SetHeader "Content-Type: text/html"    
  fi

  if GetHeader "Content-Type" | egrep 'text/html|text/javascript' > /dev/null ; then
    gzip -c > $temp < $1
    content="$temp"

    SetHeader "Content-Encoding: gzip"
  fi

  SetDefaultHeads
  SetHeader "Content-Length: `stat -f '%z' ${content}`"

  FlushHeaders

  cat ${content}
}

function InvokeAction
{
  temp=$(mktemp)
  action=$1
  shift
  . "actions/${action}" "$@" > ${temp}
  output "$temp"
}

function serve
{
  declare -a headers
  headerIndex=0
  requestLine=""
  uri=""
  method=""
  version=""

  while read line; do 
    line=${line%%$'\r'*}

    if [[ "$requestLine" == "" ]]; then
      requestLine=$line

      segments=( $line )
      method="${segments[0]}"
      uri="${segments[1]}"
      version="${segments[2]}"

      if [[ "$uri" == "" ]] || [[ "$version" == "" ]]; then
        output 400 "Bad Request"
        exit 1
      fi

    else
      headers[$headerIndex]="$line"
      ((headerIndex++))
    fi

    if [[ "$line" == "" ]]; then

      export URI="${uri}"
      export METHOD="${method}"

      match=0

      while read -r line; do
        pattern=${line%% *}
        action=${line#* }

        if [[ "${uri}" =~ ^${pattern}$ ]]; then
            matches=( "${BASH_REMATCH[@]}" )
            unset matches[0]

            InvokeAction "${action}" "${matches[@]}"

            match=1
        fi
      done < ./routes.txt

      if [[ $match -eq 0 ]]; then
        output 404 "Not Found"
      fi

      requestLine=""
      headers=()

      ResetHeaders
      HeaderOut=0
    fi
  done
}

httpsh() {
  serve
}
