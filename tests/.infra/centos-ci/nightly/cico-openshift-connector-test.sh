#!/usr/bin/env bash
# Copyright (c) 2018 Red Hat, Inc.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
set -x

echo "========Starting nigtly test job $(date)========"

source tests/.infra/centos-ci/functional_tests_utils.sh

function runOpenshiftConnectorTest(){
    docker run --shm-size=4096m -p 5920:5920 \
    -e TS_SELENIUM_HEADLESS=true \
    -e TS_SELENIUM_LOAD_PAGE_TIMEOUT=420000 \
    -e TS_SELENIUM_WORKSPACE_STATUS_POLLING=20000 \
    -e TS_SELENIUM_BASE_URL=${CHE_ROUTE} \
    -e TS_SELENIUM_LOG_LEVEL=DEBUG \
    -e TS_SELENIUM_USERNAME=${TEST_USERNAME} \
    -e TS_SELENIUM_PASSWORD=${TEST_USERNAME} \
    -e TS_SELENIUM_MULTIUSER=true \
    -e DELETE_WORKSPACE_ON_FAILED_TEST=true \
    -e TS_SELENIUM_START_WORKSPACE_TIMEOUT=900000 \
    -e NODE_TLS_REJECT_UNAUTHORIZED=0 \
    -e TEST_SUITE=test-openshift-connector \
    -e TS_GITHUB_TEST_REPO_ACCESS_TOKEN=990040386b7d5bdf4f57001de4659e03a0b352e7 \
    -e TS_GITHUB_TEST_REPO=chepullreq4/Spoon-Knife \
    -e NODE_TLS_REJECT_UNAUTHORIZED=0 \
    quay.io/eclipse/che-e2e:nightly
}


function prepareCustomResourcePatchFile() {
  cat > /tmp/custom-resource-patch.yaml <<EOL
spec:
  auth:
    updateAdminPassword: false
EOL
    
    cat /tmp/custom-resource-patch.yaml
}

setupEnvs
installKVM
installDependencies
prepareCustomResourcePatchFile
installCheCtl
installAndStartMinishift
deployCheIntoCluster --che-operator-cr-patch-yaml=/tmp/custom-resource-patch.yaml
defineCheRoute
createTestUserAndObtainUserToken
runOpenshiftConnectorTest
echo "=========================== THIS IS POST TEST ACTIONS =============================="
getOpenshiftLogs
archiveArtifacts "che-nightly-openshift-connector"
if [[ "$IS_TESTS_FAILED" == "true" ]]; then exit 1; fi
