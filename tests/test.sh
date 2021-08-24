#!env bash

echo "testing is running ... "
echo "pwd:" `pwd`

source ./functions.sh



unit() {
  echo "123"
}

cat tests/data/simple_request.req | httpsh | grep '200 OK' > /dev/null || echo "Simple request test failed. "
cat tests/data/bad_request.req | httpsh | grep 'Bad Request' > /dev/null || echo "Bad Request Assertion failed. "
test `cat tests/data/double_requests.req | httpsh |grep 'Bash Http Server'|wc -l` -eq "2" || echo "Double request assertion failed. "

ResetHeaders; SetHeader "Content-Type: 123 456"; [[ "${ResponseHeaders[0]}" == "Content-Type: 123 456" ]] || echo "SetHeader assertion failed. "
echo "${ResponseHeaders[0]}"

echo 'ok'