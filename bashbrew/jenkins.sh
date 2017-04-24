#!/bin/bash
#*
#  This file modified from it's origin 'travis.sh'
#  to work in a jenkins environment
#
#*#

set -e
set -x
cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

repos=( --all )
extraCommands=

upstreamRepo='jnbnyc/docker-images'  # upstreamRepo='docker-library/official-images'
upstreamBranch='master'
# if [ "$JENKINS_PULL_REQUEST" -a "$JENKINS_PULL_REQUEST" != 'false' ]; then
# 	upstreamRepo="$JENKINS_REPO_SLUG"
# 	upstreamBranch="$JENKINS_BRANCH"
# fi

HEAD="$(git rev-parse --verify HEAD)"

git fetch -q "https://github.com/$upstreamRepo.git" "refs/heads/$upstreamBranch"
UPSTREAM="$(git rev-parse --verify FETCH_HEAD)"

if [ "$JENKINS_BRANCH" = 'master' -a "$JENKINS_PULL_REQUEST" = 'false' ]; then
	# if we're testing master itself, RUN ALL THE THINGS
	echo >&2 'Testing master -- BUILD ALL THE THINGS!'
elif [ "$(git diff --numstat "$UPSTREAM...$HEAD" -- . | wc -l)" -ne 0 ]; then
	# changes in bashbrew/ -- keep "--all" so we test the bashbrew script changes appropriately
	echo >&2 'Changes in bashbrew/ detected!'
	extraCommands=1
else
	repos=( $(git diff --numstat "$UPSTREAM...$HEAD" -- ../library | awk -F '/' '{ print $2 }') )
	extraCommands=1
fi

if [ "${#repos[@]}" -eq 0 ]; then
	echo >&2 'Skipping test builds: no changes to library/ or bashbrew/ in PR'
	exit
fi

export BASHBREW_LIBRARY="$(dirname "$PWD")/library"

cmds=(
	'list'
	'list --uniq'
	'cat'
)
if [ "$extraCommands" ]; then
	cmds+=(
		'list --build-order'
		'from'
	)
fi

export PS4=$'\n\n$ '
for cmd in "${cmds[@]}"; do
	( set -x && bashbrew $cmd "${repos[@]}" )
done
echo; echo
