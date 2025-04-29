#!/usr/bin/env bash

INTERACTIVE="FALSE"

# Verify some Repo URL and token have been given, otherwise we must be interactive mode.
if [ -z "$GITHUB_PAT" ] || [ -z "$GITHUB_REPOSITORY_NAME" ]; then
    echo "GITHUB_PAT and GITHUB_REPOSITORY_NAME cannot be empty"
    exit 1
fi

echo "Requesting remove token..."
REMOVE_TOKEN=$(curl -s \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${GITHUB_PAT}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/${GITHUB_REPOSITORY_NAME}/actions/runners/remove-token | jq ".token" -r)

printf "Removing runner\n"
. $HOME/config.sh remove --token $REMOVE_TOKEN --unattended
