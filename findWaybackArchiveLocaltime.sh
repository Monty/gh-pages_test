#!/usr/bin/env bash
# Check if a URL is archived in the Wayback Machine

if ! type -p "jq" >/dev/null; then
    printf "==> [Error] Can't run jq.\n" >&2
    printf "Install jq from https://stedolan.github.io/jq/download/ " >&2
    printf "then re-run this script.\n\n" >&2
    exit 1
fi

if [[ $1 =~ ^http(s)?://* ]]; then
    targetURL=$1
else
    targetURL=https://$1
fi

# Save the dictionary in case we need to parse it further
waybackResult=$(curl -s "https://archive.org/wayback/available?url=$targetURL")

waybackURL=$(jq -r '.archived_snapshots.closest.url |
    select(. != null)' <<<"$waybackResult")

if [[ $waybackURL =~ ^http(s)?://* ]]; then
    waybackTimeStamp=$(jq -r '.archived_snapshots.closest.timestamp' <<<"$waybackResult" |
        jq -r 'tostring | strptime("%Y%m%d%H%M%S") | mktime | strflocaltime("%Y-%m-%d %H:%M:%S")')
    printf "==> %s was last archived at %s as:\n" "$targetURL" "$waybackTimeStamp"
    printf "    %s\n" "$waybackURL"
    printf "    ([archive](%s))\n" "$waybackURL"
else
    printf "==> %s has not been archived.\n" "$targetURL"
fi
