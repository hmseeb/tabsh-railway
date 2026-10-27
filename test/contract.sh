#!/bin/bash
# Contract test against a running deploy. Usage: test/contract.sh <base-url> <password>
set -uo pipefail
B=${1%/}; P=$2; fail=0
ok() { if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1: got $2 want $3"; fail=1; fi; }
code() { curl -s -o /dev/null -w '%{http_code}' "$@"; }
host=${B#*://}

ok "healthz open"             "$(code "$B/healthz")" 200
ok "app locked"               "$(code "$B/app/")" 401
ok "api locked"               "$(code "$B/api/sessions")" 401
ok "api junk token"           "$(code -H "Authorization: Bearer junk" "$B/api/sessions")" 401
ok "open locked with token"   "$(code -H "Authorization: Bearer junk" "$B/open?token=junk")" 401
ok "wrong password"           "$(code -u admin:nope "$B/app/")" 401
loc=$(curl -s -o /dev/null -w '%{redirect_url}' -u "admin:$P" "$B/"); loc=$(echo "$loc" | sed "s#//[^@]*@#//#")
tok=${loc##*#token=}
ok "/ pairs this app"         "$(echo "$loc" | grep -c "^$B/app/#token=")" 1
ok "api with token"           "$(code -H "Authorization: Bearer $tok" -H "Origin: ${B%%://*}://$host" "$B/api/sessions")" 200
ok "foreign origin refused"   "$(code -H "Authorization: Bearer $tok" -H "Origin: https://evil.example" "$B/api/sessions")" 403
ok "no token refused"         "$(code -u "admin:$P" -H "Origin: ${B%%://*}://$host" "$B/api/sessions")" 401
ok "ws without token"         "$(code -H "Connection: Upgrade" -H "Upgrade: websocket" -H "Sec-WebSocket-Version: 13" -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" "$B/ws?id=x")" 401
exit $fail
