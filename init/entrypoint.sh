#!/bin/sh
set -e

#echo "checking who I am"
#whoami
#echo "checking where I am"
#pwd
#echo "checking whats in the directory"
#ls
#echo "checking whats in /home"
#ls /home
#echo "checking whats in /root"
#ls /root

if [[ ! -z "$TOKEN" ]]; then
	TF_ENV_TOKEN=$TOKEN
fi

if [[ -z "$TF_ENV_TOKEN" ]]; then
	echo "Set the TF_ENV_TOKEN env variable."
	exit 1
fi

/bin/cat > /home/.terraformrc << EOM
credentials "app.terraform.io" {
  token = "$TF_ENV_TOKEN"
}
EOM

/bin/cat /home/.terraformrc

cd "${TF_ACTION_WORKING_DIR:-.}"

set +e
OUTPUT=$(sh -c "terraform init -no-color -input=false $*" 2>&1)
SUCCESS=$?
echo "$OUTPUT"
set -e

if [ $SUCCESS -eq 0 ]; then
    exit 0
fi

if [ "$TF_ACTION_COMMENT" = "1" ] || [ "$TF_ACTION_COMMENT" = "false" ]; then
    exit $SUCCESS
fi

COMMENT="#### \`terraform init\` Failed
\`\`\`
$OUTPUT
\`\`\`"
PAYLOAD=$(echo '{}' | jq --arg body "$COMMENT" '.body = $body')
COMMENTS_URL=$(cat /github/workflow/event.json | jq -r .pull_request.comments_url)
curl -s -S -H "Authorization: token $GITHUB_TOKEN" --header "Content-Type: application/json" --data "$PAYLOAD" "$COMMENTS_URL" > /dev/null

exit $SUCCESS

