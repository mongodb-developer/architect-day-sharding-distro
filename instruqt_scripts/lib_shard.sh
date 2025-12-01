#!/bin/bash
# Use LIB_SH_PATH environment variable if provided, else default to /scripts/lib.sh
source "${LIB_SH_PATH:-"/scripts/lib.sh"}"

success="\033[0;32m[lib-shard:INFO]\033[0m"
err="\033[0;31m[lib-shard:ERROR]\033[0m"
warn="\033[0;33m[lib-shard:WARNING]\033[0m"

smsg() {
  echo -e "${success} ${1}"
}
wmsg() {
  echo -e "${warn} ${1}"
}
emsg() {
  echo -e "${err} ${1}"
}

# This function, `copy_to_hosts`, is used to copy a file from a source path to a destination path
# across multiple MongoDB shard servers. It performs the following steps:
#
# Parameters:
#   - $1: The source file path (src_path) to be copied.
#   - $2: The destination file path (dest_path) where the file will be copied on the shard servers.
#
# Steps:
#   1. Extracts the directory path from the destination file path (dest_dir).
#   2. Iterates over shard servers (shard-2, shard-3, and shard-4 in this case).
#   3. For each shard server:
#      a. Constructs the shard host address using the shard number and the `_SANDBOX_DNS` variable.
#      b. Creates the destination directory on the shard server using `ssh`.
#      c. Copies the source file to the destination path on the shard server using `scp`.
#
# Notes:
#   - The function assumes that the `_SANDBOX_DNS` environment variable is set and contains the DNS suffix for the shard servers.
#   - The `ssh` command uses the `StrictHostKeyChecking=accept-new` option to automatically accept new host keys.
#   - The function currently targets shard servers 2, 3, and 4, but this can be modified by adjusting the loop.
copy_to_hosts() {
  local src_path=${1}
  local dest_path=$2
  local dest_dir=$(dirname "$dest_path")

  for i in 2 3 4; do
    SHARD_HOST="mongodb-shard-$i.${_SANDBOX_DNS}"
    smsg "Copying $src_path to $SHARD_HOST:$dest_path"
    ssh -o StrictHostKeyChecking=accept-new root@${SHARD_HOST} "mkdir -p $dest_dir"
    scp "$src_path" root@${SHARD_HOST}:"$dest_path"
  done
}

# Function to batch variable updates
# Store variables to be updated on remote hosts in memory to avoid multiple SSH connections
# NOTE: Uses associative arrays, introduced in Bash version 4.0 (https://linuxhandbook.com/bash-associative-arrays/)
# Declare keyword allows use of additional flags
declare -A _pending_remote_updates

###############################################################################
# begin_var_batch
#
# This function initializes a new batch of variable updates for remote hosts.
# Call this before a series of set_var_multi calls to optimize SSH sessions.
#
# Example:
# begin_var_batch
# set_var_multi DB_NAME "myDatabase"
# set_var_multi DB_USER "myUser"
# apply_var_batch
#
# No parameters
###############################################################################
begin_var_batch() {
  # Initialize/clear the associative array
  declare -g -A _pending_remote_updates=() # -g (global), -A (associative array)
  smsg "Beginning new batch of variable updates"
}

###############################################################################
# apply_var_batch
#
# This function applies all queued variable updates in a single SSH session per host.
# Call this after a series of set_var_multi calls to execute the batched updates.
#
# No parameters
###############################################################################
apply_var_batch() {
  if [ ${#_pending_remote_updates[@]} -eq 0 ]; then # Gets the length of the array, not the number of elements
    smsg "No pending variable updates to apply"
    return 0
  fi

  smsg "Applying batched variable updates to ${#_pending_remote_updates[@]} hosts"

  # For each host that has pending updates
  for host in "${!_pending_remote_updates[@]}"; do
    local host_vars="${_pending_remote_updates[$host]}"
   local common_dir=$(echo "$host_vars" | grep -o 'COMMON_DIR=.*' | cut -d'=' -f2) # Extract COMMON_DIR value

    # If common dir is not set, skip this host
    if [ -z "$common_dir" ]; then
      emsg "Error: COMMON_DIR not found in updates for host $host"
      continue
    fi

    smsg "Updating multiple variables on $host in one SSH session"

    # Execute all variable updates in a single SSH session
    ssh -o StrictHostKeyChecking=accept-new root@"$host" "bash -s" <<EOF
# Create the complete directory structure with explicit path
mkdir -p "$common_dir"

if [ ! -f "$common_dir/runtimevars.sh" ]; then
    echo "#!/bin/bash" > "$common_dir/runtimevars.sh"
    echo "source /scripts/lib.sh" >> "$common_dir/runtimevars.sh"
elif ! grep -q "^source /scripts/lib.sh" "$common_dir/runtimevars.sh"; then
    # Add source line after the shebang
    sed -i '1a source /scripts/lib.sh' "$common_dir/runtimevars.sh"
fi

$(echo "$host_vars" | grep -v 'COMMON_DIR=' | while IFS='=' read -r var_name value; do
  echo "if grep -q \"^set_var $var_name \" \"$common_dir/runtimevars.sh\"; then"
  echo "    sed -i \"s|^set_var $var_name .*|set_var $var_name \\\"$value\\\"|\" \"$common_dir/runtimevars.sh\""
  echo "else"
  echo "    echo \"set_var $var_name \\\"$value\\\"\" >> \"$common_dir/runtimevars.sh\""
  echo "fi"
done)
EOF
  done

  # Set the value to an empty array since we are done with the current batch
  # Avoids reusing stale data
  declare -g -A _pending_remote_updates=()
}

###############################################################################
# queue_remote_var_update
#
# This function queues a variable update for a remote host.
# Instead of updating immediately, it stores the update for later batch processing.
#
# Parameters:
#   $1 - The target host (e.g., mongodb-shard-2.example.com).
#   $2 - The name of the variable (e.g., DB_NAME).
#   $3 - The value for the variable.
#   $4 - The COMMON_DIR path
###############################################################################
queue_remote_var_update() {
  local host="$1"
  local var_name="$2"
  local value="$3"
  local common_dir_path="$4"

  # Initialize host entry if it doesn't exist
  if [ -z "${_pending_remote_updates[$host]}" ]; then
    _pending_remote_updates[$host]="COMMON_DIR=$common_dir_path"
  fi

  # Add this variable update to the queue
  _pending_remote_updates[$host]="${_pending_remote_updates[$host]}
$var_name=$value"
}

###############################################################################
# update_remote_agent_var
#
# This function updates (or appends) a variable in the agent vars file on a remote host.
# The file is assumed to be located at "$COMMON_DIR/runtimevars.sh" on the remote system.
#
# Parameters:
#   $1 - The target host (e.g., mongodb-shard-2.example.com).
#   $2 - The name of the variable (e.g., DB_NAME).
#   $3 - The value for the variable.
#   $4 - The COMMON_DIR path
#
# Behavior:
#   - If a batch is in progress (begin_var_batch was called), variable update is queued
#   - Otherwise, it performs an immediate update via SSH
###############################################################################
update_remote_agent_var() {
  local host="$1"
  local var_name="$2"
  local value="$3"
  local common_dir_path="$4"

  # If we have a pending batch, add to it
  if [ ${#_pending_remote_updates[@]} -gt 0 ]; then
    queue_remote_var_update "$host" "$var_name" "$value" "$common_dir_path"
    return
  fi

  # Otherwise, perform immediate update (legacy behavior)
  local remote_file="${common_dir_path}/runtimevars.sh"

  ssh -o StrictHostKeyChecking=accept-new root@"$host" "bash -s" <<EOF
# Create the complete directory structure with explicit path
mkdir -p "${common_dir_path}"

if [ ! -f "${common_dir_path}/runtimevars.sh" ]; then
    echo "#!/bin/bash" > "${common_dir_path}/runtimevars.sh"
    echo "source /scripts/lib.sh" >> "${common_dir_path}/runtimevars.sh"
elif ! grep -q "^source /scripts/lib.sh" "${common_dir_path}/runtimevars.sh"; then
    # Add source line after the shebang
    sed -i '1a source /scripts/lib.sh' "${common_dir_path}/runtimevars.sh"
fi
if grep -q "^set_var $var_name " "${common_dir_path}/runtimevars.sh"; then
    sed -i "s|^set_var $var_name .*|set_var $var_name \"$value\"|" "${common_dir_path}/runtimevars.sh"
else
    echo "set_var $var_name \"$value\"" >> "${common_dir_path}/runtimevars.sh"
fi
EOF
}

###############################################################################
# set_var_multi
#
# This function sets a variable both locally and on multiple remote hosts.
# It serves as a drop-in replacement for set_var but with added remote functionality.
#
# Parameters:
#   $1 - The name of the variable.
#   $2 - (Optional) The value for the variable. If not provided, uses the current value.
#   $3 - (Optional) Flag to control auto-propagation to shards (default: "auto").
#        - "auto": Automatically propagate to shard-2, shard-3, and shard-4
#        - "local": Only set locally, don't propagate to any shards
#        - Any other value: Treat as a host name and only propagate to specified hosts
#
# Behavior:
#   - Sets the variable in the current environment (like set_var)
#   - Stores the variable using agent variable set or in local file (like set_var)
#   - By default, updates the variable on shard-2, shard-3, and shard-4 hosts
#   - Can be restricted to local-only by passing "local" as the third parameter
#   - Can target specific hosts by passing them as additional parameters
#
# Examples:
#   set_var_multi DB_NAME "myDatabase"           # Local + auto-propagate to shard-2, 3, and 4
#   set_var_multi DB_NAME "myDatabase" "local"   # Local only, no propagation
###############################################################################
set_var_multi() {
  # Get the variable name and value (same logic as set_var)
  local name=${1?Error: Missing variable name}
  local value=${2:-${!name}}
  echo "set_var_multi: Name(${name}) Value(${value})"

  if ! is_var_set value; then
    echo "Error: value not set for '${name}'"
    exit 1
  fi

  # Set locally just like set_var
  export ${name}="${value}"

  if is_local_mode; then
    echo "export ${name}=\"${value}\"" >>${AGENT_VARS_FILE}
  else
    agent variable set ${name} "${value}"
  fi

  # Shift away the first two arguments to get to the propagation flag or host list
  shift 2

  # Determine if we should auto-propagate or use specific hosts
  local auto_propagate=true
  local hosts=()

  # If we have additional arguments
  if [ $# -gt 0 ]; then
    if [ "$1" = "local" ]; then
      auto_propagate=false
      shift
    elif [ "$1" != "auto" ]; then
      auto_propagate=false
      hosts=("$@")
    else
      shift
      hosts=("$@")  # Collect any additional hosts
    fi
  fi

  # If auto-propagation is enabled, add shard-2, shard-3, and shard-4 to the hosts list
  if [ "$auto_propagate" = true ] && is_var_set _SANDBOX_DNS; then
    hosts+=("mongodb-shard-2.${_SANDBOX_DNS}" "mongodb-shard-3.${_SANDBOX_DNS}" "mongodb-shard-4.${_SANDBOX_DNS}")
  fi

  # If we have hosts to update
  if [ ${#hosts[@]} -gt 0 ]; then
    # Handle if we are defining COMMON_DIR itself
    local common_dir_path
    if [ "$name" = "COMMON_DIR" ]; then
      common_dir_path="$value"
    elif is_var_set COMMON_DIR; then
      common_dir_path="${COMMON_DIR}"
    else
      emsg "Error: COMMON_DIR is not defined. Please set it before calling set_var_multi with remote hosts."
      return 1
    fi

    smsg "Queueing/Updating ${name} on ${#hosts[@]} remote hosts"

    # Update on each remote host
    for host in "${hosts[@]}"; do
      update_remote_agent_var "${host}" "${name}" "${value}" "${common_dir_path}"
    done
  fi
}

###############################################################################
# deploy_config_files
#
# This function copies MongoDB configuration files from shard-specific subdirectories
# to their respective hosts, replacing DNS placeholders as needed.
#
# Parameters:
#   $1 - Base source directory containing subdirs 1, 2, 3, 4 (e.g., /app/<slug>/etc)
#   $2 - DNS value to replace SANDBOX_DNS placeholder with
#
# Behavior:
#   1. For each shard number (1, 2, 3, 4):
#      a. Checks if source_dir/N exists
#      b. If shard 1 (local), copies files to local /etc/
#      c. If shards 2-4, copies files to those remote hosts' /etc/
#   2. Updates DNS placeholders in all .conf files on each host
###############################################################################
deploy_config_files() {
  local base_source_dir=${1?Error: Missing base source directory}
  local dns_value=${2?Error: Missing DNS value}

  # Create a temporary directory for modified configs
  local temp_dir=$(mktemp -d)

  # Process each shard
  for shard_num in 1 2 3 4; do
    local source_dir="${base_source_dir}/${shard_num}"

    # Check if source directory for this shard exists
    if [ ! -d "$source_dir" ]; then
      wmsg "Configuration source directory ${source_dir} does not exist, skipping shard ${shard_num}"
      continue
    fi

    # Clear the temp directory for this shard
    rm -f ${temp_dir}/*

    # Copy files to temp directory
    cp "$source_dir"/* ${temp_dir}/

    # Update MongoDB specific conf files in temp directory first
    for mongo_conf in mongos.conf; do
      local temp_conf_file="${temp_dir}/${mongo_conf}"
      if [ -f "$temp_conf_file" ]; then
        smsg "Updating DNS in ${mongo_conf} for shard ${shard_num}"
        sed -i "s/SANDBOX_DNS/${dns_value}/g" "$temp_conf_file"
      fi
    done

    if [ "$shard_num" == "1" ]; then
      # For shard 1 (local host), copy from temp to /etc/
      smsg "Deploying updated configuration to local /etc/"
      cp ${temp_dir}/* /etc/
    else
      # For remote shards, copy from temp to remote /etc/
      local shard_host="mongodb-shard-${shard_num}.${_SANDBOX_DNS}"
      smsg "Deploying updated configuration to ${shard_host}:/etc/"

      # Create remote directory and copy the already-updated files
      ssh -o StrictHostKeyChecking=accept-new root@${shard_host} "mkdir -p /etc"
      scp ${temp_dir}/* root@${shard_host}:/etc/
    fi
  done

  # Clean up temp directory
  rm -rf ${temp_dir}

  smsg "Configuration deployment complete for all shards"
}




