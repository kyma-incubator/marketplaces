# Releases

This document describes how the release flow looks like and how to create a marketplace release.

## Release process

The release process is based on Git tags. Once tag is created the release process will start automatically.

### Versioning

Marketplace versioning should follow the Kyma versions. So Marketplace in version 1.1.1 will install Kyma in version 1.1.1. Versions with suffix will generate pre-release.

### Create release

Follow these steps to create a new Marketplace release (instruction is based on release 1.1.0):

1. Checkout the master branch with the latest changes:
    ```
    git checkout master
    git pull
    ```
2. Create a release branch
   ```
   git checkout -b release-1.1
   git push origin release-1.1
   ```
3. Create a Pull Request wit all needed changes
4. Merge Pull Request to release branch
5. Checkout release branch
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

    >**NOTE:** If you want to push the tag to the upstream, run the following command:
    >```
    >git push upstream 1.1.0
    >```
8. Monitor release job
9. Check release notes on [GitHub.com](https://github.com/kyma-incubator/marketplaces/releases)

>**NOTE:** All further patches should be merged and tagged in corresponding release branch.