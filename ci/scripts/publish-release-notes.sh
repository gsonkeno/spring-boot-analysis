#!/bin/bash
set -e

source $(dirname $0)/common.sh

milestone=$( cat version/version )
if [[ $RELEASE_TYPE = "RELEASE" ]]; then
	milestone=${milestone%.RELEASE}
fi
milestone_number=$( curl -s "https://api.github.com/repos/${GITHUB_ORGANIZATION}/${GITHUB_REPO}/milestones" -u ${GITHUB_USERNAME}:${GITHUB_PASSWORD} | jq -r --arg MILESTONE "${milestone}" '.[]  | select(.title == $MILESTONE) | .number')

pushd release-notes-repo > /dev/null
run_maven clean install
java -jar -Dreleasenotes.github.organization=${GITHUB_ORGANIZATION} -Dreleasenotes.github.name=${GITHUB_REPO} target/github-release-notes-generator-0.0.1-SNAPSHOT.jar "${milestone_number}" release-notes.md
popd > /dev/null


body=$( while read line; do echo -n "$line\\n"; done < release-notes-repo/release-notes.md )

curl \
	-s \
	-u ${GITHUB_USERNAME}:${GITHUB_PASSWORD} \
	-H "Content-type:application/json" \
	-d "{\"tag_name\":\"v${milestone}\",\"name\":\"v${milestone}\",\"body\": \"${body}\"}"  \
	-f \
	-X \
	POST "https://api.github.com/repos/${GITHUB_ORGANIZATION}/${GITHUB_REPO}/releases" > /dev/null || { echo "Failed to publish" >&2; exit 1; }
