#!/usr/bin/env bash
set -e
set -u

readonly SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly REPOSITORY_DIR="$( cd "${SCRIPT_DIR}/../" && pwd )"
readonly RELEASE_VERSION="${PULL_BASE_REF}" # PULL_BASE_REF is provided by Prow
readonly ORGANIZATION="${REPO_OWNER:-"kyma-incubator"}" # REPO_OWNER is provided by Prow
readonly REPOSITORY="${REPO_NAME:-"marketplaces"}" # REPO_NAME is provided by Prow
readonly ARTIFACTS="${ARTIFACTS:-"${REPOSITORY_DIR}/tmp"}" # ARTIFACTS is provided by Prow
readonly GITHUB_TOKEN="${BOT_GITHUB_TOKEN}" # BOT_GITHUB_TOKEN is provided by Prow

log() {
    echo "$(date) [$1] $2"
}

validateEnvironment() {
    log info "Validating environment"
    local discoverUnsetVar=false

    for var in RELEASE_VERSION GITHUB_TOKEN; do
        if [ -z "${!var}" ] ; then
            log "error" "$var is not set"
            discoverUnsetVar=true
        fi
    done

    if [ "${discoverUnsetVar}" = true ] ; then
        exit 1
    fi
}
validateEnvironment

PRERELEASE="false"
if [[ $RELEASE_VERSION == *"-"* ]]; then
    PRERELEASE="true"
fi
readonly PRERELEASE

# find latest tag from which the generator should started
# shellcheck disable=SC2046
TAG_LIST_STRING=$(git describe --tags $(git rev-list --tags) --always | grep -F . | grep -vw "^${RELEASE_VERSION}$" | grep -v "-" || echo "")
TAG_LIST=($(echo "${TAG_LIST_STRING}" | tr " " "\n"))
PENULTIMATE=${TAG_LIST[0]}

if [ "${PENULTIMATE}" = "" ]; then
    log "info" "PENULTIMATE tag does not exist, first commit of repository will be use."
    PENULTIMATE=$(git rev-list --max-parents=0 HEAD)
fi

#generate release changelog
docker run --rm -v "${REPOSITORY_DIR}":/repository -w /repository -e FROM_TAG="${PENULTIMATE}" -e NEW_RELEASE_TITLE="${RELEASE_VERSION}" -e GITHUB_AUTH="${GITHUB_TOKEN}" -e CONFIG_FILE=.github/package.json eu.gcr.io/kyma-project/changelog-generator:0.2.0 sh /app/generate-release-changelog.sh;

# Create draft release
log "info" "Creating a draft release ${RELEASE_VERSION}"
RELEASE_ID=$(curl --fail -L -X POST "https://api.github.com/repos/${ORGANIZATION}/${REPOSITORY}/releases" \
    -H "Content-Type: application/json" \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    -d @- << EOF
{
  "tag_name": "${RELEASE_VERSION}",
  "name": "${RELEASE_VERSION}",
  "body": $(jq -Rs '.' "${REPOSITORY_DIR}/.changelog/release-changelog.md"),
  "draft": true,
  "prerelease": ${PRERELEASE}
}
EOF
)
RELEASE_ID=$(echo "${RELEASE_ID}" | jq '.id' )
readonly RELEASE_ID
echo

if [[ -z ${RELEASE_ID} ]]; then
    log error "Failed to create GitHub release. Exiting with error."
    exit 1
fi

# Upload artifacts
log "info" "Uploading files to draft release ${RELEASE_VERSION}"
for path in "${ARTIFACTS}"/*; do
    [[ -f ${path} ]] || continue
    log "info" "Uploading ${path}"

    curl --fail -L --data-binary @"${path}" \
        -H "Content-Type: application/octet-stream" \
        -H "Authorization: token ${GITHUB_TOKEN}" \
        "https://uploads.github.com/repos/${ORGANIZATION}/${REPOSITORY}/releases/${RELEASE_ID}/assets?name=$(basename "${path}")"
done
echo

# Make release final
log "info" "Making release ${RELEASE_VERSION} final"

curl --fail -L -X PATCH "https://api.github.com/repos/${ORGANIZATION}/${REPOSITORY}/releases/${RELEASE_ID}" \
    -H "Content-Type: application/json" \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    -d @- << EOF
{
  "draft": false
}
EOF