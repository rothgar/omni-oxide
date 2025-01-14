#!/bin/bash

#set -x

# Creates an instance using the template defined in the same folder
# will name instances off of the number passed to the script or pick a random number if one is not provided

export i=${1:-$RANDOM}

oxide instance create --project omni --json-body <(envsubst < instance.json.template)
