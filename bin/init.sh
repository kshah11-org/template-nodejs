#!/bin/bash
echo "Authorizing GitHub"
gh auth login
echo "Authorized GitHub"
echo "Enter Project name:"
read project
read -p "Organisation [kshah11-org]: " organisation
organisation=${organisation:-kshah11-org}
template=$(git remote get-url --push origin)
echo "Template is ${template}"
gh repo create ${organisation}/${project} --template="${template}" --public
echo "Succesfully initialized ${project}"
cd ../
echo "Navigated to parent folder"
echo "Cloning Repo ${project}"
gh repo clone ${organisation}/${project} ${project}
echo "Repo Cloned"
FILE=.env
if [ -f "$FILE" ]; then
  echo "Copying snyk and sonar envs"
  cp ./template-nodejs/${FILE} ./${project}/
else
  echo "Env file not found."
fi
cd ${project}
repo=$(git remote get-url --push origin)
tmp=$(mktemp)
jq '.name = "'${project}'"' package.json > "$tmp" && mv "$tmp" package.json
jq '.description = "'${project}'"' package.json > "$tmp" && mv "$tmp" package.json
echo "Package.json file updated name and description with value ${project}"
jq '.repository.url = "git+'${repo}'"' package.json > "$tmp" && mv "$tmp" package.json
jq '.bugs.url = "https://github.com/'${organisation}'/'${project}'/issues"' package.json > "$tmp" && mv "$tmp" package.json
jq '.homepage = "https://github.com/'${organisation}'/'${project}'#readme"' package.json > "$tmp" && mv "$tmp" package.json
echo "Package.json file updated relevant urls with value ${project}"
sed -i '' "/sonar.projectKey=/ s/=.*/=kush-${project}/" sonar-project.properties
sed -i '' "/sonar.projectName=/ s/=.*/=${project}/" sonar-project.properties
echo "Sonar properties file updated project key and name with value ${project}"
# export NVM_DIR=$HOME/.nvm
# source $NVM_DIR/nvm.sh
nvm use
npm install
npx snyk monitor
git add .
git commit -m "feat: update Package.json file"
git push
echo "Repo URL: ${repo}"
echo "Opening project in VSCode..."
code .
