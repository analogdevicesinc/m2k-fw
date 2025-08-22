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
                "vivado-version":"'${VIVADO_VERSION}'",
                "package-version":"'${PACKAGE_VERSION}'",
                "trigger-id":"'${TRIGGER_ID}'"
                }
        }')

if [[ ! -z $(echo "$post" | grep "HTTP/2 20*" ) ]]; then
    echo "Post request to trigger private workflow success!"

    # Search for the triggered build using the opensource sent run id
    run_search=""
    while [[ $(echo "$run_search" | grep ^'      "name":' | \
                cut -d "-" -f2 | sed 's#"##g' | sed 's#,##g' | \
                sed 's# ##g' | awk 'NR==1{print $NF}') != ${TRIGGER_ID} ]]; do
        run_search=$(curl -s -L \
                    -H "Accept: application/vnd.github+json" \
                    -H "Authorization: Bearer ${GH_TRIGGER_TOKEN}" \
                    -H "X-GitHub-Api-Version: 2022-11-28" \
                    https://api.github.com/repos/adi-innersource/hdl-builds/actions/workflows/${PRIVATE_WORKFLOW}/runs)
    done
    echo "Catched the triggered run build! Checking the status of m2k-fw build ..."

    # Check status of the run by getting private run id
    run_id=$(echo "$run_search" | grep ^'      "id":' | awk 'NR==1{print $NF}' | cut -d ":" -f2 | sed 's#,##g')

    run_status=""
    while [[ "$run_status" != "completed" ]]; do
        sleep 60
        run_status=$(curl -s -L \
                    -H "Accept: application/vnd.github+json" \
                    -H "Authorization: Bearer ${GH_TRIGGER_TOKEN}" \
                    -H "X-GitHub-Api-Version: 2022-11-28" \
                    https://api.github.com/repos/adi-innersource/hdl-builds/actions/runs/${run_id} | \
                    grep ^'  "status":' | cut -d ":" -f2 | sed 's#"##g' | sed 's#,##g' | sed 's# ##g')
        echo "Status of m2k-fw build: ${run_status} ..."

        # Check if it was cancelled
        conclusion=$(echo "$run_status"| grep ^'      "conclusion":' | \
                        awk 'NR==1{print $NF}' | cut -d ":" -f2 | sed 's#,##g')
        if [ "$conclusion" == "cancelled" ]; then
            echo "Build was cancelled ... exiting!"
            exit 1
        fi

    done
    echo "Build finished! Getting result ..."

    # Get build result conclusion
    conclusion=$(echo "$run_status"| grep ^'      "conclusion":' | \
                    awk 'NR==1{print $NF}' | cut -d ":" -f2 | sed 's#,##g')

    if [ "$conclusion" != "success" ]; then
        echo "Build failed!"
        exit 1
    else
        echo "Build finished successfuly!"
    fi

else
    echo "Post request to trigger private workflow failed ..."
    echo "$post"
    exit 1
fi
