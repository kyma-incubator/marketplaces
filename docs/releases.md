# Releases

This document describes how the release flow looks like and how to create a Marketplace release.

## Release process

The release process is based on Git tags. Once a tag is created, the release process starts automatically.

### Versioning

Marketplace versioning should follow Kyma versions. Marketplace in version 1.1.1 installs Kyma in version 1.1.1. Versions with a suffix generate pre-releases.

### Create a release

Follow these steps to create a new Marketplace release:
>**NOTE:** This instruction is based on the release 1.1.0.

1. Check out the `master` branch with the latest changes:
    ```
    git checkout master
    git pull
    ```
2. Create a release branch.
   ```
   git checkout -b release-1.1
   git push origin release-1.1
   ```
3. Create a Pull Request (PR) with all required changes.
4. Merge the PR to the release branch.
5. Check out the release branch:
    ```
    git checkout release-1.1
    git pull
    ```
6. Create a tag with the proper release version:

    ```
    git tag 1.1.0
    ```   

7. Push the tag:

    ```
    git push {remote} 1.1.0
    ```

    **NOTE:** If you want to push the tag to the upstream, run the following command:
    ```
    git push upstream 1.1.0
    ```
8. Monitor the release job.
9. Check release notes on [GitHub.com](https://github.com/kyma-incubator/marketplaces/releases).

>**NOTE:** Merge all further patches to the corresponding release branch and tag it accordingly.