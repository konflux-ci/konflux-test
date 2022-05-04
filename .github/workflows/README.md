Release Workflow:

  We use Github actions workflow for our release process, which means when we are ready to release, we create a release/v1.2.3 from the main branch. Uses .github/workflows/release.yml to publish the release.
  
  Images are pushed to quay.io using the robot accounts credentials, Github and quay.io credentials managed in secret sections in the hacbs-test repo project settings. While triggering the release, the inputs are passed in GitHub event context to release the specific tag for the release version.
  
  Once the Image pushed to quay.io, the release section gets updated with the latest tag version in the hacbs-test repo.
 
Triggering a release:
  Select the Actions tab and choose release workflow from the list of workflows. 
  Click on the Run Workflow event trigger.
  Now enter the version to be released, already prefixed with `v`
  Make sure the release branch specified as `main`
  Click on Run Workflow to trigger the release.
