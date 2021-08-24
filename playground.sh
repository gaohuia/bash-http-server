#!env bash

cwd=$(cd `dirname $0`; pwd)
cd "${cwd}"

uri="/users/123"


while read line; do
    echo "$line"
    pattern=${line%% *}
    action=${line#* }

    echo "matching ${pattern}"

    if [[ "${uri}" =~ ^${pattern}$ ]]; then
        matches=( "${BASH_REMATCH[@]}" )
        unset matches[0]
        echo "${action}" "${matches[@]}"
    fi
done < ./routes.txt


