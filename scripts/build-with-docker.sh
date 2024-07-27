#! /bin/bash

set -euo pipefail

orig_cwd="$(readlink -f .)"

this_dir="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"/

bash "$this_dir"/create-build-container.sh -u "$(id -u):$(id -g)" -- bash scripts/build-in-container.sh

# done!
# you should now have the binary in your current working directory
