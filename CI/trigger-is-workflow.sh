#!/bin/bash

# Trigger private repository workflow
post=$(curl -s -i -L -X POST \
        --url "https://api.github.com/repos/${PRIVATE_ORG}/${PRIVATE_REPO}/actions/workflows/${PRIVATE_WORKFLOW}/dispatches" \
        --header "Accept: application/vnd.github+json" \
        --header "Authorization: Bearer ${GH_TRIGGER_TOKEN}" \
        -d \
        '{
            "ref":"develop",
            "inputs": {
                "hdl-project-repo":"https://github.com/analogdevicesinc/m2k-fw.git",
                "hdl-project-branch":"master",
                "hdl-project-name":"m2k-fw",
                "vivado-version":"2023.2",
                "package-version":"test.1.0",
                "workflow-trigger":"true"
                }
        }')

if [[ ! -z $(echo "$post" | grep "HTTP/2 20*" ) ]]; then
    echo "Post request to trigger private workflow success !"
else
    echo "Post request to trigger private workflow failed ..."
    echo "$post"
    exit 1
fi
