#!/usr/bin/env bash
set -euo pipefail

CHANGED_FILES=$(git diff --name-only HEAD~1)
PIPELINE_FILE="pipeline.generated.yml"
echo "steps:" > "$PIPELINE_FILE"

# Helper function to add a job
add_job() {
  local label=$1
  local command=$2
  local queue=$3
  local cpu=$4
  local memory=$5
  local job_size=${queue#production-}

  cat <<EOF >> "$PIPELINE_FILE"
  - label: ":rocket: $label"
    command: "$command"
    agents:
      queue: "$queue"
    env:
      CPU: "$cpu"
      MEMORY: "$memory"
      JOB_SIZE: "$job_size"

EOF
}

# Logic for matching files and adding jobs
for file in $CHANGED_FILES; do
  case "$file" in
    core/*)
      add_job "test-core" "./scripts/test-core.sh" "production-large" 4 "8G"
      ;;
    docs/*)
      add_job "lint-docs" "./scripts/lint-docs.sh" "production-small" 1 "1G"
      ;;
    api/*)
      add_job "build-api" "./scripts/build-api.sh" "production-medium" 2 "4G"
      ;;
  esac
done

# Upload pipeline
buildkite-agent pipeline upload "$PIPELINE_FILE"
