## Release Workflow

  We use Github actions workflow for our release process, which means when we are ready to release, we create a release/v1.2.3 from the main branch. Uses .github/workflows/release.yml to publish the release.

  Images are pushed to quay.io using the robot accounts credentials, Github and quay.io credentials managed in secret sections in the konflux-test repository project settings. While triggering the release, the inputs are passed in Github event context to release the specific tag for the release version.

  Once the Image pushed to quay.io, the release section gets updated with the latest tag version in the konflux-test repo.

#### Triggering a release
  1. Select the Actions tab and choose release workflow from the list of workflows.
  2. Click on the Run Workflow event trigger.
  3. Now enter the version to be released, will be automatically prefixed with 'v'. Example: 1.2.3 . Bump version using [semantic versioning](https://semver.org/) based on changes to be released.
  4. Make sure the release branch is set to `main`
  5. Click on Run Workflow to trigger the release.
