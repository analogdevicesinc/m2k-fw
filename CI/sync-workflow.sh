#!/bin/bash

run_status=""

# Check status of the private workflow once 5 minutes
while [[ "$run_status" != "completed" ]]; do
    run_status=$(curl -s -L \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${GH_TRIGGER_TOKEN}" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        https://api.github.com/repos/${PRIVATE_ORG}/${PRIVATE_REPO}/actions/runs/${PRIVATE_RUN} | \
        grep ^'  "status":' | cut -d ":" -f2 | sed 's#"##g' | sed 's#,##g' | sed 's# ##g')
            
        echo "Status of m2k build: ${run_status} ..."

        # Wait for the next request
        sleep 300
done
    echo "Trigger run done!"
