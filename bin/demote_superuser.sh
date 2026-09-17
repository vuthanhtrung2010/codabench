#!/usr/bin/env bash
set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <username_or_email>"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Check if running in host with active docker compose django container
if command -v docker &> /dev/null && docker compose ps --status running -q django 2>/dev/null | grep -q .; then
    docker compose exec django python manage.py demote_superuser "$@"
elif [ -f "$REPO_ROOT/src/manage.py" ]; then
    if command -v uv &> /dev/null; then
        (cd "$REPO_ROOT" && uv run python src/manage.py demote_superuser "$@")
    else
        python "$REPO_ROOT/src/manage.py" demote_superuser "$@"
    fi
elif [ -f "$REPO_ROOT/manage.py" ]; then
    python "$REPO_ROOT/manage.py" demote_superuser "$@"
else
    echo "Error: Could not locate manage.py or running Django container."
    exit 1
fi
