#!/usr/bin/env bash

INTERACTIVE="FALSE"
if [ "$(echo $INTERACTIVE_MODE | tr '[:upper:]' '[:lower:]')" == "true" ]; then
	INTERACTIVE="TRUE"
fi

if [ -z "$GITHUB_REPOSITORY_URL" ] || [ -z "$GITHUB_PAT" ] || [ -z "$GITHUB_REPOSITORY_NAME" ] || [ -z "$RUNNER_NAME" ]; then
	if [ "$INTERACTIVE" == "FALSE" ]; then
		echo "GITHUB_REPOSITORY_URL, GITHUB_PAT, GITHUB_REPOSITORY_NAME and RUNNER_NAME cannot be empty"
		exit 1
	fi
fi

ADDITIONAL_ARGS=""

if [[ -n "${RUNNER_LABELS:-}" ]]; then
	# Must not start or end with a comma
    if [[ "$RUNNER_LABELS" == ,* || "$RUNNER_LABELS" == *, ]]; then
        echo "Error: RUNNER_LABELS must not start or end with a comma"
        exit 1
    fi

    # Must not contain any whitespace
    if [[ "$RUNNER_LABELS" =~ [[:space:]] ]]; then
        echo "Error: RUNNER_LABELS must not contain spaces"
        exit 1
    fi

    ADDITIONAL_ARGS="$ADDITIONAL_ARGS --no-default-labels --labels ${RUNNER_LABELS} "
fi

if [[ -n "${REPLACE_EXISTING_RUNNER_NAME:-}" ]]; then
    case "$REPLACE_EXISTING_RUNNER_NAME" in
    true)
		ADDITIONAL_ARGS="$ADDITIONAL_ARGS --replace"
        ;;
    *)
        echo "Error: REPLACE_EXISTING_RUNNER_NAME must be 'true' or 'false' if set, got: '$REPLACE_EXISTING_RUNNER_NAME'"
        exit 1
        ;;
    esac
fi

if [[ -n "${WORK_DIR:-}" ]]; then
	ADDITIONAL_ARGS="$ADDITIONAL_ARGS --work $WORK_DIR"
fi

# Calculate default configuration values.
GITHUB_REPOSITORY_BANNER="$GITHUB_REPOSITORY_URL"
if [ -z "$GITHUB_REPOSITORY_BANNER" ]; then
	export GITHUB_REPOSITORY_BANNER="<empty repository url>"
fi


echo "Requesting registration token..."

REGISTRATION_TOKEN=$(curl -s \
  --http1.1 \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${GITHUB_PAT}" \
  https://api.github.com/repos/${GITHUB_REPOSITORY_NAME}/actions/runners/registration-token | jq ".token" -r)


printf "Configuring GitHub Runner for $GITHUB_REPOSITORY_BANNER\n"
printf "\tRunner Name: $RUNNER_NAME\n\tAdditional args: $ADDITIONAL_ARGS\n"

if [ "$INTERACTIVE" == "FALSE" ]; then
	printf "Running in non-interactive mode\n"
	. $HOME/config.sh --name $RUNNER_NAME --url $GITHUB_REPOSITORY_URL --token $REGISTRATION_TOKEN $ADDITIONAL_ARGS --unattended
else
	. $HOME/config.sh --name $RUNNER_NAME --url $GITHUB_REPOSITORY_URL --token $REGISTRATION_TOKEN $ADDITIONAL_ARGS
fi

# Start the runner.
printf "Executing GitHub Runner for $GITHUB_REPOSITORY_NAME\n"

GITHUB_PAT="" bash $HOME/run.sh
