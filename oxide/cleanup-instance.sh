#!/bin/bash

# Will delete an instance and disk
# Need to provide instance name or id

PROJECT=omni
INSTANCE=${1}

# Turn off instances first
function stop-instance() {
	oxide instance stop --project ${PROJECT} --instance ${INSTANCE}
}

function delete-instance() {
	oxide instance delete --project ${PROJECT} --instance ${INSTANCE}
}

function get-disk() {
	oxide instance disk list --project ${PROJECT} --instance ${INSTANCE} \
		| jq -r '.[].id'
}

function delete-disk() {
	oxide disk delete --disk ${DISK}
}

function get-instance-state() {
	oxide instance view --project ${PROJECT} --instance ${INSTANCE} \
		| jq -r '.run_state'
}

DISK=$(get-disk)
stop-instance

while true; do
	state=$(get-instance-state)
	if [[ "$state" == "stopped" ]]; then
		break
	fi
	sleep 2s
done

delete-instance
delete-disk
