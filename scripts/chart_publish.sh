#!/bin/bash
set -euo pipefail

# Set up script variables
CHARTS_DIR=./charts
GITREPO_NAME=daml-helm-charts
GITREPO_OWNER=digital-asset
PUBLISH_BRANCH=main
PUBLISH_FOLDER=publish


#Set up a workspace for the script
mkdir $PUBLISH_FOLDER
helm repo add $GITREPO_NAME https://$GITREPO_OWNER.github.io/$GITREPO_NAME/
git config user.email "machine@digitalasset.com"
git config user.name "machine-da"


# Loop through the helm charts in the designated directory
for chart in $CHARTS_DIR/*; do
    # Get the chart name and version from the Chart.yaml file and load them into variables
    chart_name=$(yq eval '.name' $chart/Chart.yaml)
    chart_version=$(yq eval '.version' $chart/Chart.yaml)

    # Check if the chart with the version stored in the variable has already been pushed to the repo
    if helm search repo $GITREPO_NAME/$chart_name -o yaml  -l | grep -w "version: $chart_version"; then
        echo "Chart $chart_name version $chart_version already exists in repository $GITREPO_NAME"
    else
        # Packaging the updated chart and uploading it as a release
        helm package $chart -d $PUBLISH_FOLDER/
        cr upload -b https://api.github.com/ -u https://uploads.github.com --skip-existing -c $PUBLISH_BRANCH -r $GITREPO_NAME  -p $PUBLISH_FOLDER --owner $GITREPO_OWNER --token $1
        echo "Chart $chart_name version $chart_version has been pushed to repository $GITREPO_NAME"
        helm repo index $PUBLISH_FOLDER --url https://github.com/$GITREPO_OWNER/$GITREPO_NAME/releases/download/$chart_name-$chart_version --merge docs/index.yaml
        rm -rf $PUBLISH_FOLDER/$chart_name-$chart_version.tgz

    fi
done

# Overwrite the old index file with the merged index file.
mv publish/index.yaml docs/index.yaml

# CR index doesnt work for multiple reasons. One being it uses a folder to create an index and it has no file merge capabilities therefore only the files present in the folder would be added to the index. In our case, we store the already published helm charts as github releases, cr index do not take these into account.
#cr index --pr --pages-branch $PUBLISH_BRANCH -b https://api.github.com/ -u https://uploads.github.com -i docs/index.yaml -r $GITREPO_NAME  -p $PUBLISH_FOLDER --owner $GITREPO_OWNER --token $1

#We don't need the packaged charts anymore so we remove the whole folder.
rm -rf $PUBLISH_FOLDER

#Now we need to create a new branch with the changes of the index yaml file and create a PR so that our index.yaml file contains our new releases.
#-$CIRCLE_BUILD_NUM
if [[ -z $(git status -s) ]]; then
  echo "No changes to push"
else
  echo "Pushing changes"
  git add docs/index.yaml
  git checkout -b "$PUBLISH_BRANCH-index-update" --track
  git commit -m "Updated index.yaml file so that it contains the newly pushed helm charts"
  git push -f origin "$PUBLISH_BRANCH-index-update"
  current_pr_closed=$(gh pr status --json closed -q '.currentBranch.closed')
  if [[ -z $current_pr_closed ]] || [[ $current_pr_closed == "true" ]] ; then
    echo "Opening new PR."
    gh pr create --fill
  else
    echo "PR already exists. Please merge or close the existing PR first"
  fi
fi

helm repo update $GITREPO_NAME
helm search repo $GITREPO_NAME -l  
echo "The release(s) published by this pipeline run will be visible after merging in the created PR and then waiting for up to 2 minutes so that the github page can be rebuilt. Afterwards running helm repo update {reponame} and then helm search {reponame} will display the newly released helm chart versions."