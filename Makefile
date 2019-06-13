authenticate:
	gcloud config set project kyma-project
	gcloud auth configure-docker
	gcloud config configurations list

master-build: authenticate
	make -C initializer/ ci-master
	make -C google-cloud/ ci-master

pr-build: authenticate
	make -C initializer/ ci-pr
	make -C google-cloud/ ci-pr

release: authenticate
	make -C initializer/ ci-release
	make -C google-cloud/ ci-release
	exec scripts/release.sh

ci-master: master-build
ci-pr: pr-build
ci-release: release