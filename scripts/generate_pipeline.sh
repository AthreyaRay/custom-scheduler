#!/bin/bash
set -euo pipefail

# Get the list of changed files in the last commit
CHANGED_FILES=$(git diff --name-only HEAD~1)

# Define jobs as associative arrays
declare -A JOB1=(
  [name]="test-core"
  [paths]="core/"
  [command]="./scripts/test-core.sh"
  [cpu]=4
  [memory]="8G"
  [queue]="production-large"
)

declare -A JOB2=(
  [name]="lint-docs"
  [paths]="docs/"
  [command]="./scripts/lint-docs.sh"
  [cpu]=1
  [memory]="1G"
  [queue]="production-small"
)

declare -A JOB3=(
  [name]="build-api"
  [paths]="api/"
  [command]="./scripts/build-api.sh"
  [cpu]=2
  [memory]="4G"
  [queue]="production-medium"
)

ALL_JOBS=(JOB1 JOB2 JOB3)

# Begin YAML
PIPELINE_FILE="pipeline.generated.yml"
echo "steps:" > "$PIPELINE_FILE"

# Loop through jobs and add matching ones to pipeline
for JOB_VAR in "${ALL_JOBS[@]}"; do
  eval "declare -A JOB=\"\${$JOB_VAR[@]}\""
  
  MATCHED=false
  for FILE in $CHANGED_FILES; do
    if [[ "$FILE" == ${!JOB[prefix]*} || "$FILE" == ${JOB[paths]}* ]]; then
      MATCHED=true
      break
    fi
  done

  if $MATCHED; then
    cat <<EOF >> "$PIPELINE_FILE"
  - label: ":rocket: ${JOB[name]}"
    command: "${JOB[command]}"
    agents:
      queue: "${JOB[queue]}"
    env:
      CPU: "${JOB[cpu]}"
      MEMORY: "${JOB[memory]}"
      JOB_SIZE: "${JOB[queue]#production-}"
EOF
  fi
done

# Upload the generated pipeline
buildkite-agent pipeline upload "$PIPELINE_FILE"
