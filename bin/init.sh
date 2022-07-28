echo "Authorizing GitHub"
gh auth login
echo "Authorized GitHub"
echo "Enter Project name:"
read project
template=$(git remote get-url --push origin)
echo "Template is ${template}"
gh repo create kshah11/${project} --template="${template}" --public
echo "Succesfully initialized ${project}"
cd ../
echo "Navigated to parent folder"
echo "Cloning Repo ${project}"
gh repo clone kshah11/${project} ${project}
echo "Repo Cloned"
cd ${project}
repo=$(git remote get-url --push origin)
tmp=$(mktemp)
jq '.name = "'${project}'"' package.json > "$tmp" && mv "$tmp" package.json
jq '.description = "'${project}'"' package.json > "$tmp" && mv "$tmp" package.json
echo "Package.json file updated name and description with value ${project}"
jq '.repository.url = "git+'${repo}'"' package.json > "$tmp" && mv "$tmp" package.json
jq '.bugs.url = "https://github.com/kshah11/'${project}'/issues"' package.json > "$tmp" && mv "$tmp" package.json
jq '.homepage = "https://github.com/kshah11/'${project}'#readme"' package.json > "$tmp" && mv "$tmp" package.json
echo "Package.json file updated relevant urls with value ${project}"
sed -i '' "/sonar.projectKey=/ s/=.*/=kush-${project}/" sonar-project.properties
sed -i '' "/sonar.projectName=/ s/=.*/=${project}/" sonar-project.properties
echo "Sonar properties file updated project key and name with value ${project}"
export NVM_DIR=$HOME/.nvm
source $NVM_DIR/nvm.sh
nvm use
npm install
git add .
git commit -m "feat: update Package.json file"
git push
npx snyk monitor
npm run sonarcloud
echo "Repo URL: ${repo}"
echo "Opening project in VSCode..."
code .

# Todo:
# 1. Error during SonarScanner execution - SONAR_TOKEN var cant be read
# snyk token isnt needed..?
