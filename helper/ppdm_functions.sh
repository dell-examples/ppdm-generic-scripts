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
    local SCRIPT_SOURCE="$1"
    local SCRIPT_NAME="$2"
    local DESCRIPTION="$3"
    local VERBOSE="${VERBOSE:-false}"

    shift 3

    # ===== Read script content =====
    local SCRIPT_CONTENT
    if [[ "$SCRIPT_SOURCE" =~ ^https:// ]]; then
        [[ "$VERBOSE" == "true" ]] && echo "Downloading script from URL: $SCRIPT_SOURCE"
        SCRIPT_CONTENT=$(curl -s "$SCRIPT_SOURCE")
        if [[ -z "$SCRIPT_CONTENT" ]]; then
            echo "❌ Failed to download script from URL: $SCRIPT_SOURCE"
            return 1
        fi
    elif [[ -f "$SCRIPT_SOURCE" ]]; then
        [[ "$VERBOSE" == "true" ]] && echo "Reading script from local file: $SCRIPT_SOURCE"
        SCRIPT_CONTENT=$(<"$SCRIPT_SOURCE")
        if [[ -z "$SCRIPT_CONTENT" ]]; then
            echo "❌ Script file is empty or unreadable: $SCRIPT_SOURCE"
            return 1
        fi
    else
        echo "❌ Invalid script source: $SCRIPT_SOURCE"
        return 1
    fi

    # ===== Build parameters array =====
    local PARAM_ARRAY=()
    for param in "$@"; do
        IFS=',' read -r ALIAS VALUE DISPLAYNAME TYPE <<< "$param"
        PARAM_JSON=$(jq -n \
            --arg alias "$ALIAS" \
            --arg value "$VALUE" \
            --arg displayName "$DISPLAYNAME" \
            --arg type "$TYPE" \
            '{alias: $alias, value: $value, displayName: $displayName, type: $type}')
        PARAM_ARRAY+=("$PARAM_JSON")
    done

    local PARAMETERS_JSON
    PARAMETERS_JSON=$(printf '%s\n' "${PARAM_ARRAY[@]}" | jq -s '.')

    # ===== Build JSON payload =====
    local JSON_PAYLOAD
    JSON_PAYLOAD=$(jq -n \
        --arg content "$SCRIPT_CONTENT" \
        --arg name "$SCRIPT_NAME" \
        --arg description "$DESCRIPTION" \
        --argjson parameters "$PARAMETERS_JSON" \
        '{
            extendedData: {
                subTypes: ["GENERIC_PAAS_DATABASE"],
                type: "ASSET"
            },
            content: $content,
            name: $name,
            systemPredefined: false,
            parameters: $parameters,
            osType: "LINUX",
            purpose: "BACKUP",
            type: "BACKUP",
            description: $description
        }')

    [[ "$VERBOSE" == "true" ]] && echo "Uploading script '$SCRIPT_NAME' to PPDM..."

    # ===== Upload via curl using temp file =====
    local RESPONSE_FILE
    RESPONSE_FILE=$(mktemp)
    local HTTP_STATUS

    HTTP_STATUS=$(curl -sk -w "%{http_code}" -o "$RESPONSE_FILE" -X POST "https://${PPDM_FQDN}:8443/api/v3/scripts" \
        -H "Authorization: Bearer $PPDM_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$JSON_PAYLOAD")

    if [[ "$HTTP_STATUS" == "200" || "$HTTP_STATUS" == "201" ]]; then
        echo "✅ Upload succeeded."
    else
        echo "❌ Upload failed. HTTP status: $HTTP_STATUS"
        echo "Response:"
        cat "$RESPONSE_FILE" | jq .
    fi

    rm -f "$RESPONSE_FILE"
}

