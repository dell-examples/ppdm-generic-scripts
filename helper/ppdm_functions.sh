#!/bin/bash
urlencode() {
    # urlencode <string>

    old_lc_collate=${LC_COLLATE:-''}
    LC_COLLATE=C

    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:$i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf '%s' "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done

    LC_COLLATE=$old_lc_collate
}

urldecode() {
    # urldecode <string>

    local url_encoded="${1//+/ }"
    printf '%b' "${url_encoded//%/\\x}"
}
function ppdm_curl {
    local url
    url="https://${PPDM_FQDN}:8443/api/v2/${1#/}"
    shift || return # fail if we weren't passed at least x args
    local sleep_seconds=10
    local retry=0
    local retries=5
    local result=""
    local return_code=1
    while [[ -z $result && "$return_code" != 0 ]]
        do
        if [[ $retry -gt $retries ]]
            then
            echo "exceeded max retries of $retries" >&2
            break
        fi
        [[ "${DEBUG}" == "TRUE" ]] && echo $url ${ppdm_curl_args[@]} >&2
        result=$(curl -ks "$url" \
        "${ppdm_curl_args[@]}" "$@"
        )
        return_code=$?
        [[ "${DEBUG}" == "TRUE" ]] && echo $return_code >&2
        [[ "${DEBUG}" == "TRUE" ]] && echo $result >&2
        [[ "${DEBUG}" == "TRUE" ]] && echo $retry >&2
        ((retry++))

        if [[ $(echo $result | jq -e 'select(.code != null)' 2> /dev/null) ]]
            ### eval section for return code will be added here
            then
                local errorlevel=$(echo $result | jq -e '.code' 2> /dev/null) 
                local reason=$(echo $result | jq -e '.reason' 2> /dev/null) 
                case $errorlevel in 
                    400|401)
                    echo "access denied" >&2
                    break
                    ;;
                    404)
                    echo "resource does not exist or is deleted" >&2
                    break
                    ;;
                    423)
                    echo "user locked, waiting for 5 Minutes " >&2
                    sleep 300
                    ;;
                    500|501|503)
                    echo "received $errorlevel, Server might be busy, waiting for 30 Seconds " >&2
                    sleep 30
                    ;;
                    *)
                    echo "current State $errorlevel with $reason" >&2
                    ;;
                esac    
                local result=""
        fi
    done 
    echo -E $result  | jq -e . 2>/dev/null
}



function get_ppdm_token {
    local password=$1
    local ppdm_adminuser=${PPDM_ADMINUSER:-admin}
    ppdm_curl_args=(
    -XPOST    
    -H 'content-type: application/json' 
    -d '{"username":"'${ppdm_adminuser}'","password":"'${password}'"}')
    local response=$(ppdm_curl login  | jq -r '.access_token')
    if [[ "$response" == "null" ]]
    then 
        echo "error retrieving token"
        return 1
    else    
        echo $response
    fi        
}



function set_ppdm_scripts {
    local SCRIPT_FILE="$1"        # Path to bash script file
    local SCRIPT_NAME="$2"        # Script name (PPDM script object name)
    local DESCRIPTION="$3"        # Script description    


    shift 3                      # Remaining args are param specs
    # ===== Read and escape script content for JSON =====
    if [[ ! -f "$SCRIPT_FILE" ]]; then
        echo "Script file not found: $SCRIPT_FILE" >&2
        return 1
    fi

    local SCRIPT_CONTENT
    SCRIPT_CONTENT=$(<"$SCRIPT_FILE" sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | awk '{printf "%s\\n", $0}')
    # Escape newlines and quotes in the script content

    # ===== Build the parameters array from remaining arguments =====
    local PARAMETERS_JSON=""

    for param in "$@"; do
        # Each param must be in the format: alias,value,displayName,type
        IFS=',' read -r ALIAS VALUE DISPLAYNAME TYPE <<< "$param"
        # Escape double quotes in value/displayName (optional)
        VALUE_ESCAPED=$(echo "$VALUE" | sed 's/"/\\"/g')
        DISPLAYNAME_ESCAPED=$(echo "$DISPLAYNAME" | sed 's/"/\\"/g')

        PARAMETERS_JSON+=$(cat <<EOPARAM
{
  "alias": "$ALIAS",
  "value": "$VALUE_ESCAPED",
  "displayName": "$DISPLAYNAME_ESCAPED",
  "type": "$TYPE"
},
EOPARAM
)
    done
    # Remove trailing comma
    PARAMETERS_JSON=$(echo "$PARAMETERS_JSON" | sed '$s/,$//')

    # ===== Build the full JSON payload =====
    local JSON_PAYLOAD
    JSON_PAYLOAD=$(cat <<EOF
{
  "extendedData": {
    "subTypes": [
      "GENERIC_PAAS_DATABASE"
    ],
    "type": "ASSET"
  },
  "content": "$SCRIPT_CONTENT",
  "name": "$SCRIPT_NAME",
  "systemPredefined": false,
  "parameters": [
    $PARAMETERS_JSON
  ],
  "osType": "LINUX",
  "purpose": "BACKUP",
  "type": "BACKUP",
  "description": "$DESCRIPTION"
}
EOF
)

    # ===== Debug output =====
    echo "==== Debug: JSON Payload ===="
    echo "$JSON_PAYLOAD"
    echo "==== End JSON Debug ===="
    echo $PPDM_FQDN
    echo $PPDM_TOKEN
    # ===== Upload via verbose curl =====
    local RESPONSE
    RESPONSE=$(curl -skvvv -X POST "https://${PPDM_FQDN}:8443/api/v3/scripts" \
        -H "Authorization: Bearer $PPDM_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$JSON_PAYLOAD" 2>&1)

    echo "==== cURL response ===="
    echo "$RESPONSE"

}
