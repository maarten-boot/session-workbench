#!/bin/bash
# What changed per release, from the git history (SPEC §4.6 About):
# the subject line of each commit (merges left out) between two v* tags.
#
#   scripts/changes.sh                  for the app (frontend/public/changes.txt):
#                                       the commits since the last tag, if any,
#                                       then the last 5 releases, newest first
#   scripts/changes.sh --release vX.Y.Z the release notes of that tag
#
# Output is Markdown: "## <heading>" and "- <subject>" lines.
# Run it from the repository root, or anywhere inside the repository.
# Plain bash 3.2 (macOS's /bin/bash): no mapfile; no "| head", which would
# end git with SIGPIPE and fail the pipeline.
set -euo pipefail

MAX_RELEASES=5
MAX_LINES=60 # commits per section

subjects() { # <range>
	git log --no-merges -n "$MAX_LINES" --format='- %s' "$1"
}

# The v* tags in the history of $1, newest version first.
tags() {
	git tag --merged "$1" --list 'v*' --sort=-v:refname
}

# previous <tag>: the tag before it, or nothing.
previous() {
	local t
	t=$(tags "$1^" 2>/dev/null || true)
	echo "${t%%$'\n'*}"
}

if [ "${1:-}" = --release ]; then
	tag=${2:?usage: changes.sh --release <tag>}
	prev=$(previous "$tag")
	if [ -n "$prev" ]; then
		echo "## Changes since $prev"
		echo
		subjects "$prev..$tag"
	else
		echo "## Changes"
		echo
		subjects "$tag"
	fi
	exit 0
fi

all=()
while IFS= read -r t; do all+=("$t"); done < <(tags HEAD)
if [ ${#all[@]} -eq 0 ]; then
	echo "## Changes (not released)"
	subjects HEAD
	exit 0
fi
if [ "$(git rev-parse HEAD)" != "$(git rev-parse "${all[0]}^{commit}")" ]; then
	echo "## Since ${all[0]} (not released)"
	subjects "${all[0]}..HEAD"
	echo
fi
for ((i = 0; i < ${#all[@]} && i < MAX_RELEASES; i++)); do
	tag=${all[i]}
	echo "## $tag ($(git log -1 --format=%cs "$tag^{commit}"))"
	if ((i + 1 < ${#all[@]})); then
		subjects "${all[i + 1]}..$tag"
	else
		subjects "$tag"
	fi
	echo
done
