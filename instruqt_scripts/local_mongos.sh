# This script provides utility functions to manage a locally-hosted mongos instance.
#!/bin/bash
set -euo pipefail

# Use LIB_SH_PATH if set (for tests), otherwise use the default path.
source "${LIB_SH_PATH:-"/scripts/lib.sh"}"

# Function: is_mongos_running
# Description: Checks if a s instance is running.
# Usage: is_mongos_running
# Parameters: None
# Returns: 0 if mongos is running, 1 otherwise
is_mongos_running() {
  echo "Checking if mongos is running"
  # excludes "defunct" processes even if they are named "mongos"
  if pgrep -x mongos >/dev/null 2>&1 && ! pgrep -x mongos | xargs ps -o stat= | grep -q 'Z'; then
    return 0
  fi
  return 1
}

# Function: start_mongos
# Description: Start a locally-hosted mongos instance
# Usage: start_mongos
# Parameters: None
start_mongos() {
  if ! is_mongos_running; then
    echo "Calling start_mongos using $MONGOS_CONF config file"

    # Check if the MONGOS_CONF environment variable is unset or empty
    if [[ -z "${MONGOS_CONF:-}" ]]; then
      MONGOS_CONF="/etc/mongos.conf"
    fi

    mongos --config "$MONGOS_CONF"
    echo "Successfully started mongos."
  else
    echo "mongos is already running."
  fi
}