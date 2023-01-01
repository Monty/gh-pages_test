#!/usr/bin/env bash
#
# Check if a URL is archived in the Wayback Machine
# Print the archive URL
# Offer to update the archive for that URL
# Offer to check again

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

# Grab the Wayback Machine dictionary
waybackResult=$(curl -s "https://archive.org/wayback/available?url=$targetURL")

waybackURL=$(jq -r '.archived_snapshots.closest.url |
    select(. != null)' <<<"$waybackResult")

if [[ $waybackURL =~ ^http(s)?://* ]]; then
    raw_timestamp=$(jq -r '.archived_snapshots.closest.timestamp' <<<"$waybackResult" |
        jq -r 'tostring | strptime("%Y%m%d%H%M%S")')
    UTC_timestamp=$(jq -r 'strftime("%Y-%m-%d %H:%M:%S")' <<<"$raw_timestamp")
    local_timestamp=$(jq -r 'mktime | strflocaltime("%Y-%m-%d %H:%M:%S")' <<<"$raw_timestamp")

    printf "==> %s was last archived at:\n" "$targetURL"
    printf "    %s (%s UTC) as:\n" "$local_timestamp" "$UTC_timestamp"
    printf "    %s\n" "$waybackURL"

    # for @a@pdx.social
    printf "==> For use in md files\n"
    printf "    ([archive](%s))\n" "$waybackURL"
else
    printf "==> %s has not been archived.\n" "$targetURL"
fi

# Offer to update the archive for the URL even if one was already found
printf "\n"
read -r -p "Request a current archive of $targetURL? [y/N] " YESNO
shift
if [ "$YESNO" != "y" ]; then
    exit
else
    printf "Saving %s on the Wayback Machine...\n" "$targetURL"
    open "https://web.archive.org/save/$targetURL"
    printf "\n"
    read -r -p "Check $targetURL again? [y/N] " YESNO
    shift
    if [ "$YESNO" != "y" ]; then
        exit
    else
        printf "\n"
        exec $0 "$targetURL"
    fi
fi
