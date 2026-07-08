#!/usr/bin/env bash
# swile-design Stop/SubagentStop gate — universel (macOS /bin/bash, Linux, Git Bash). Sans jq.
# Sentinelle .swile-verify.json : etat = en_cours | en_attente_verdict | bloque | fini ; clean = true/false.
# Bloque uniquement : lock sans sentinelle, ou etat en_cours / clean:false.

input="$(cat)"
log="$HOME/.swile-gate.log"
ts="$(date '+%Y-%m-%d %H:%M:%S')"

case "$input" in
  *'"stop_hook_active":true'*) echo "[$ts] sh skip stop_hook_active" >> "$log"; exit 0;;
esac

cwd_esc="$(printf '%s' "$input" | sed -n 's/.*"cwd":"\([^"]*\)".*/\1/p')"
cwd="$(printf '%s' "$cwd_esc" | sed 's/\\\\/\//g; s/\\/\//g')"
echo "[$ts] sh invoked cwd=$cwd" >> "$log"
[ -z "$cwd" ] && exit 0

lock="$cwd/.swile-run.lock"
sent="$cwd/.swile-verify.json"

if [ ! -f "$lock" ]; then echo "[$ts] sh pass no-lock" >> "$log"; exit 0; fi

if [ ! -f "$sent" ]; then
  echo "[$ts] sh BLOCK lock-sans-sentinelle" >> "$log"
  printf '%s' '{"decision":"block","reason":"[swile-design] .swile-run.lock present mais pas de .swile-verify.json : la verification n a pas ete faite. Execute verify() jusqu a count:0 + compareToSource + reconcile(), ecris .swile-verify.json (etat + clean), puis supprime .swile-run.lock si le run est fini."}'
  exit 0
fi

s="$(cat "$sent" 2>/dev/null)"
etat="$(printf '%s' "$s" | sed -n 's/.*"etat"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
case "$s" in *'"clean":true'*|*'"clean": true'*) clean=1;; *) clean=0;; esac

if [ "$etat" = "en_attente_verdict" ] || [ "$etat" = "bloque" ]; then
  echo "[$ts] sh pass etat=$etat" >> "$log"; exit 0
fi
if [ "$etat" = "fini" ] && [ "$clean" = "1" ]; then
  echo "[$ts] sh pass fini clean" >> "$log"; exit 0
fi
if [ -z "$etat" ] && [ "$clean" = "1" ]; then
  echo "[$ts] sh pass clean (sentinelle v1)" >> "$log"; exit 0
fi

echo "[$ts] sh BLOCK etat=${etat:-absent} clean=$clean" >> "$log"
printf '%s' '{"decision":"block","reason":"[swile-design] Sentinelle .swile-verify.json : ecran non verifie (etat en_cours ou clean:false). Termine la boucle verify() count:0 -> compareToSource -> reconcile, mets a jour la sentinelle (etat en_attente_verdict apres le temoin, fini en fin de run, bloque si panne bridge a signaler), puis reessaie."}'
exit 0
