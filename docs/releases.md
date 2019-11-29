# Release process

This document describes how to create a release of the `marketplaces` repository release before publishing it on a given Partner Portal, such as GCP Marketplace.

>**NOTE:** The release process is based on Git tags. Once a tag is created, the release process starts automatically.

## Versioning

Versioning of `marketplaces` should follow Kyma versions, so version 1.1.1 installs Kyma in version 1.1.1. Versions with a suffix generate pre-releases.

## Create a release

Follow the steps to create a new release.

>**NOTE:** This instruction is based on the release 1.1.0.

1. Clone the `marketplaces` repository on your local machine.

2. Check out the `master` branch with the latest changes:

    ```bash
    git checkout master
    git pull
    ```

3. Create a release branch:

    ```bash
   git checkout -b release-1.1
   git push upstream release-1.1
   ```

4. Create a tag with the proper release version:

    ```bash
    git tag 1.1.0
    ```

5. Push the tag:

    ```bash
    git push upstream 1.1.0
    ```

6. Monitor the status of the release job on the [Prow dashboard](https://status.build.kyma-project.io/?job=rel-marketplaces).

7. Check if the [release notes](https://github.com/kyma-incubator/marketplaces/releases) on were published on GitHub.

8. Publish the release on a given Partner Portal. This process differs depending on a the provider.

>**NOTE:** Merge all further patches to the corresponding release branch and tag it accordingly.
