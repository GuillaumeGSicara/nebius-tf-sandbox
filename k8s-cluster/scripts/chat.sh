#!/usr/bin/env bash
# One chat completion against vLLM in the cluster, through kubectl port-forward.
# Usage: scripts/chat.sh "prompt"      (env: LOCAL_PORT, MAX_TOKENS, VLLM_MODEL)
set -euo pipefail

PROMPT="${1:-Say hello in one sentence.}"
LOCAL_PORT="${LOCAL_PORT:-18000}"
URL="http://localhost:${LOCAL_PORT}/v1"

kubectl -n vllm port-forward svc/vllm "${LOCAL_PORT}:8000" >/dev/null &
PF_PID=$!
trap 'kill $PF_PID 2>/dev/null || true' EXIT

for _ in $(seq 1 30); do
  curl -sS --fail "${URL}/models" >/dev/null 2>&1 && break
  sleep 1
done

MODEL="${VLLM_MODEL:-$(curl -sS --fail-with-body "${URL}/models" | jq -er '.data[0].id')}"

RESPONSE=$(jq -n --arg model "$MODEL" --arg prompt "$PROMPT" --argjson max_tokens "${MAX_TOKENS:-null}" \
  '{model: $model, messages: [{role: "user", content: $prompt}]} + if $max_tokens then {max_tokens: $max_tokens} else {} end' \
  | curl -sS --fail-with-body -H 'Content-Type: application/json' -d @- "${URL}/chat/completions")

echo "$RESPONSE" | jq .
echo "--- answer ---"
echo "$RESPONSE" | jq -r '.choices[0].message.content'
