CHARTS_DIR=./charts
GITREPO_NAME=daml-helm-charts
GITREPO_OWNER=digital-asset
PUBLISH_BRANCH=main
PUBLISH_FOLDER=publish

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
        #cr upload -b https://api.github.com/ -u https://uploads.github.com --skip-existing -c $PUBLISH_BRANCH -r $GITREPO_NAME  -p $PUBLISH_FOLDER --owner $GITREPO_OWNER --token $1
        echo "Chart $chart_name version $chart_version has been pushed to repository $GITREPO_NAME"
        helm repo index $PUBLISH_FOLDER --url https://github.com/$GITREPO_OWNER/$GITREPO_NAME/releases/download/$chart_name-$chart_version --merge docs/index.yaml
        echo $chart_name-$chart_version.tgz
        rm -rf $PUBLISH_FOLDER/$chart_name-$chart_version.tgz
        mv $PUBLISH_FOLDER/index.yaml docs/index.yaml
    fi
done