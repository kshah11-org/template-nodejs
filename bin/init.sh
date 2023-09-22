#!/bin/bash
echo "Authorizing GitHub"
gh auth login
echo "Authorized GitHub"
echo "Enter Project name (Spaces not allowed):"
read project
read -p "Organisation [kshah11-org]: " organisation
organisation=${organisation:-kshah11-org}
cd ../
sf project:generate --name ${project}
cp -r ./template-nodejs/.github/ ${project}/.github
cp -r ./template-nodejs/NOTES.md ${project}/NOTES.md
cp -r ./template-nodejs/BACKLOG.md ${project}/BACKLOG.md
cp -r ./template-nodejs/TECHDEBT.md ${project}/TECHDEBT.md
cp -r ./template-nodejs/.prettierignore ${project}/.prettierignore
cp -r ./template-nodejs/.nvmrc ${project}/.nvmrc
cp -r ./template-nodejs/sonar-project.properties ${project}/sonar-project.properties
cp -r ./template-nodejs/.env ${project}/.env
cd ${project}
git init
sf org create scratch -d -f config/project-scratch-def.json -a ${project}
sf org display --json > org.json
scratch_org_url=$(jq -r '.result.instanceUrl' org.json)
scratch_org_token=$(jq -r '.result.accessToken' org.json)
echo "SCRATCH_ORG_URL=${scratch_org_url}" >> .env
echo "SCRATCH_ORG_TOKEN=${scratch_org_token}" >> .env
sf config set org-instance-url=${scratch_org_url} --global
sf project deploy start --source-dir force-app --ignore-conflicts --target-org ${scratch_org_token}
sed -i '' "/sonar.projectKey=/ s/=.*/=kush-${project}/" sonar-project.properties
sed -i '' "/sonar.projectName=/ s/=.*/=${project}/" sonar-project.properties
echo "Sonar properties file updated project key and name with value ${project}"
export NVM_DIR=$HOME/.nvm
source $NVM_DIR/nvm.sh
nvm use
npm install
npx snyk monitor --project-name=${project}
git add .
git commit -m "feat: initial commit"
gh repo create ${project} --push --public --source ./
echo "Opening project in VSCode..."
code .
