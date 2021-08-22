#!env bash

pwd=$(cd `dirname $0`; pwd)

cert=/usr/local/nginx/conf/any.cer
key=/usr/local/nginx/conf/any.key

( cd $pwd && socat OPENSSL-LISTEN:443,reuseaddr,fork,cert=${cert},key=${key},verify=0 EXEC:'bash http.sh' )

