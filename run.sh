#!/usr/bin/env zsh
# run.sh — launches the app with secrets loaded from .env
# Usage: ./run.sh [extra flutter run args]
#   e.g. ./run.sh -d iPhone
#        ./run.sh --flavor staging

set -e

ENV_FILE=".env"

if [ ! -f "$ENV_FILE" ]; then
  echo "❌  .env file not found."
  echo "    Copy .env.example to .env and fill in your keys."
  exit 1
fi

# Load key=value pairs, skip comments and blank lines
export $(grep -v '^\s*#' "$ENV_FILE" | grep -v '^\s*$' | xargs)

if [ -z "$GEMINI_API_KEY" ] || [ "$GEMINI_API_KEY" = "your_key_here" ]; then
  echo "⚠️   GEMINI_API_KEY is not set in .env — AI generation will be disabled."
fi

exec flutter run \
  --dart-define=GEMINI_API_KEY="${GEMINI_API_KEY:-}" \
  "$@"
