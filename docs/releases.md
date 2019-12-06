# Release process

This document describes how to create a release of the `marketplaces` repository before publishing it on a given Partner Portal, such as GCP Marketplace.

>**NOTE:** The release process is based on Git tags. Once a tag is created, the release process starts automatically.

## Versioning

Versioning of `marketplaces` should follow Kyma versions, so the release of `marketplaces` 1.1.1 installs Kyma in version 1.1.1. Versions with a suffix generate pre-releases.

## Create a release

Follow the steps to create a new release.

>**NOTE:** This instruction is based on the release 1.1.0.

1. Clone the `marketplaces` repository on your local machine.

    ```bash
    git clone git@github.com:kyma-incubator/marketplaces.git
    ```

2. Go to the `marketplaces` folder. If you cloned the repository before, make sure you are on the `master` branch:

    ```bash
    git checkout master
    ```

3. Fetch and pull the latest changes from the upstream master:

    ```bash
    git fetch --all
    git pull
    ```

4. Create a release branch:

    ```bash
   git checkout -b release-1.1
   git push upstream release-1.1
   ```

5. Create a tag with the proper release version:

    ```bash
    git tag 1.1.0
    ```

6. Push the tag:

    ```bash
    git push upstream 1.1.0
    ```

7. Monitor the status of the release job on the [Prow dashboard](https://status.build.kyma-project.io/?job=rel-marketplaces).

8. Check if the [release notes](https://github.com/kyma-incubator/marketplaces/releases) were published on GitHub.

9. Publish the release on a given Partner Portal. This process differs depending on a the provider.

>**NOTE:** Merge all further patches to the corresponding release branch and tag it accordingly.
