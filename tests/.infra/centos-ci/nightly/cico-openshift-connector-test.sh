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
  docker run maxura/e2e-tests:crl-latest -e URL=ttps://keycloak-che.$(minishift ip).nip.io/auth/realms/che/protocol/openid-connect/token
  
  : '  docker run --shm-size=4096m -p 5920:5920 \
    -e TS_SELENIUM_HEADLESS=false \
    -e TS_SELENIUM_LOAD_PAGE_TIMEOUT=420000 \
    -e TS_SELENIUM_WORKSPACE_STATUS_POLLING=20000 \
    -e TS_SELENIUM_BASE_URL="https://$CHE_ROUTE" \
    -e TS_SELENIUM_LOG_LEVEL=DEBUG \
    -e TS_SELENIUM_USERNAME=${TEST_USERNAME} \
    -e TS_SELENIUM_PASSWORD=${TEST_USERNAME} \
    -e TS_TEST_OPENSHIFT_PLUGIN_USERNAME=${TEST_USERNAME} \
    -e TS_TEST_OPENSHIFT_PLUGIN_PASSWORD=${TEST_USERNAME} \
    -e TS_TEST_OPENSHIFT_PLUGIN_PROJECT=default \
    -e TS_SELENIUM_MULTIUSER=true \
    -e DELETE_WORKSPACE_ON_FAILED_TEST=true \
    -e TEST_SUITE=test-openshift-connector \
    -e NODE_TLS_REJECT_UNAUTHORIZED=0 \
    maxura/e2e-tests:CHE-16927 || IS_TESTS_FAILED=true
    '
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
