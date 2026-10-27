#!/bin/bash
# Run inside the container as node: makes a fresh card, runs one agent command
# as that card's terminal would (TABSH_SESSION_ID set), and prints every status
# the card passed through plus its final note.
# Usage: test/agent-card.sh <label> <command...>
set -u
label=$1; shift
tok=$(cat ~/.tabsh/token); api=http://127.0.0.1:7681/api/sessions
auth=(-H "Authorization: Bearer $tok")
id=$(curl -s "${auth[@]}" -H 'content-type: application/json' -d "{\"name\":\"$label\"}" $api | node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>console.log(JSON.parse(d).id))')
card() { curl -s "${auth[@]}" $api | node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{const s=JSON.parse(d).find(x=>x.id===process.argv[1]);console.log(s.status,"|",s.note||"")})' "$id"; }
( last=; while :; do c=$(card); [ "$c" != "$last" ] && echo "  card: $c" && last=$c; sleep 0.2; done ) & w=$!
TABSH_SESSION_ID=$id TABSH_URL=http://127.0.0.1:7681 timeout 180 "$@" </dev/null >/tmp/agent-$label.out 2>&1; echo "  exit $?"
sleep 2; kill $w
echo "  output: $(tail -c 300 /tmp/agent-$label.out | tr '\n' ' ')"
