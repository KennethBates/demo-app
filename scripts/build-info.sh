$script = @'
#!/bin/sh
set -eu
REPO_URL="https://github.com/${CF_REPO_OWNER}/${CF_REPO_NAME}"

COMMITS=$(git log -n 10 --format='%H%x1f%s' | jq -R -s --arg repo "$REPO_URL" '
  split("\n") | map(select(length > 0) | split("\u001f")
  | {Id: .[0], LinkUrl: ($repo + "/commit/" + .[0]), Comment: .[1]})')

jq -n \
  --arg num "$CF_BUILD_ID" \
  --arg url "$CF_BUILD_URL" \
  --arg branch "$CF_BRANCH" \
  --arg root "$REPO_URL" \
  --arg sha "$CF_REVISION" \
  --argjson commits "$COMMITS" \
  '{BuildEnvironment:"Codefresh", BuildNumber:$num, BuildUrl:$url, Branch:$branch,
    VcsType:"Git", VcsRoot:$root, VcsCommitNumber:$sha, Commits:$commits}' \
  > /codefresh/volume/buildinfo.json

cat /codefresh/volume/buildinfo.json
'@
New-Item -ItemType Directory -Path scripts -Force | Out-Null
[IO.File]::WriteAllText("$PWD\scripts\build-info.sh", ($script -replace "`r`n", "`n"))
