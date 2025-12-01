# This script provides utility functions to manage a locally-hosted MongoDB instance.
#!/bin/bash
set -euo pipefail

# Use LIB_SH_PATH if set (for tests), otherwise use the default path.
source "${LIB_SH_PATH:-"/scripts/lib.sh"}"

# Globals
MONGOD_CONF_PATH="/etc/mongod.conf"

# Function: is_mongod_running
# Description: Checks if a mongod instance is running.
# Usage: is_mongod_running
# Parameters: None
# Returns: 0 if mongod is running, 1 otherwise
is_mongod_running() {
  echo "Checking if MongoDB is running"
  # excludes "defunct" processes even if they are named "mongod"
  if pgrep -x mongod >/dev/null 2>&1 && ! pgrep -x mongod | xargs ps -o stat= | grep -q 'Z'; then
    return 0
  fi
  return 1
}

# Function: gen_password
# Description: Generates a random password string of specified length using /dev/urandom
#
# Parameters: None
#
# Returns:
#   A random alphanumeric password string of the specified length
#
# Example usage:
#   password=$(gen_password)
gen_password() {
  echo $(head -c 16 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9')
}

# Function: start_mongod
# Description: Start a locally-hosted mongod instance
# Usage: start_mongod [config_path]
# Parameters: 
#   $1 - Path to MongoDB config file (optional, defaults to MONGOD_CONF_PATH)
start_mongod() {
  local config_path=${1:-$MONGOD_CONF_PATH}

  if ! is_mongod_running; then
    echo "Calling start_mongod with config: $config_path"

    # Check if fork is already enabled in the config
    local fork_enabled
    fork_enabled=$(yq eval '.processManagement.fork' "$config_path" 2>/dev/null || echo "false")

    if [[ "$fork_enabled" = "true" ]]; then
      # Fork is already set in config, don't use --fork
      mongod --config "$config_path"
    else
      # Fork is not set, add --fork flag
      mongod --config "$config_path" --fork
    fi

    echo "Successfully started MongoDB."
  else
    echo "MongoDB is already running."
  fi
}

# Function: enable_authentication
# Description: Enables authentication in the MongoDB configuration file.
# Parameters:
#   $1 - Path to the MongoDB configuration file (optional, defaults to MONGOD_CONF_PATH)
# Example usage:
#   enable_authentication
#   enable_authentication "/path/to/mongod.conf"
enable_authentication() {
  local conf_path=${1:-$MONGOD_CONF_PATH}
  local current_value=$(yq eval '.security.authorization' $conf_path || echo "")
  if [ "$current_value" == "enabled" ]; then
    echo "Authentication is already enabled."
  else
    yq eval '.security.authorization = "enabled"' -i $conf_path
    echo "Authentication enabled."
  fi
}

# Function: set_local_connection_string
# Description: Sets the CONNECTION_STRING and BASE_CONNECTION_STRING env variables
#
# Parameters:
#   $1 - Credentials in the format "username:password" (required)
#   $2 - Database name (optional)
#   $3 - Port number (optional, defaults to 27017)
#
# Example usage:
#   set_local_connection_string "admin:password"
#   set_local_connection_string "user:pass" "mydb" 27018
set_local_connection_string() {
  local credentials=${1:?Error: No credentials provided to set_local_connection_string}
  local db_name=${2:-""}
  local port=${3:-27017}

  local cs_domain="localhost:$port"
  local prefix="mongodb://"
  local params="?directConnection=true&authSource=admin"

  # Build connection string with or without database name
  local cs
  if [[ -z "$db_name" ]]; then
    cs="${prefix}${credentials}@${cs_domain}${params}"
  else
    cs="${prefix}${credentials}@${cs_domain}/${db_name}${params}"
  fi

  # If APP_FOLDER is not set, default to /app
  APP_FOLDER=${APP_FOLDER:-"/app"}
  set_var "BASE_CONNECTION_STRING" "${prefix}${cs_domain}"
  set_var "CONNECTION_STRING" "$cs"
  echo "export CONNECTION_STRING=\"$cs\"" >> "${APP_FOLDER}/.env"
}

# Function: set_local_admin_cs
# Description: Constructs and sets the MongoDB connection string for the admin user.
# Parameters:
#   $1 - Credentials in the format "username:password" (required)
#   $2 - Port number (optional, defaults to 27017)
#
# Usage:
#   set_local_admin_cs <username> <password> [port]
# Example:
#   set_local_admin_cs "admin" "password123"
#   set_local_admin_cs "coolUser" "password123" 27018
set_local_admin_cs() {
  local credentials=${1:?Error: No credentials provided to set_local_admin_cs}
  local port=${3:-27017}
  local cs_domain="localhost:$port"
  local prefix="mongodb://"
  local params="?directConnection=true&authSource=admin"

  local admin_cs="${prefix}${credentials}@${cs_domain}/admin"

  set_var "ADMIN_CS" "$admin_cs"
}

# Function: set_username_and_pass
# Description: Sets environment variables for a database user
#
# This function sets up environment variables for a database user:
#  - DB_USER_<USERNAME>: The username
#  - DB_PASS_<USERNAME>: The password
#  - DB_CREDS_<USERNAME>: The credentials in the format "username:password"
#
# The username is converted to uppercase for the variable names
#
# Arguments:
#   $1 - Username (required)
#   $2 - Password (required)
#
# Example:
#   set_username_and_pass "admin" "securepass"
set_username_and_pass() {
  local username=${1:?Error: Username not provided to set_username_and_pass}
  local password="${2:?Error: Password not provided to set_username_and_pass}"
  local user_keyname="DB_USER_${username^^}" # uppercase the username
  local pass_keyname="DB_PASS_${username^^}"
  local credentials_keyname="DB_CREDS_${username^^}"
  set_var "$user_keyname" "$username"
  set_var "$pass_keyname" "$password"
  set_var "$credentials_keyname" "$username:$password"
}

# Function: create_keyfile
# Description: Creates a MongoDB keyfile for internal authentication in replica sets
# Parameters:
#   $1 - Directory to store the keyfile (optional, defaults to /var/mongodb/pki)
#   $2 - Name of the keyfile (optional, defaults to mongodb-keyfile)
#
# Usage:
#   create_keyfile
#   create_keyfile "/custom/path"
#   create_keyfile "/custom/path" "custom-keyfile"
#
# Returns: Path to the created keyfile
create_keyfile() {
  local keyfile_dir=${1:-"/var/mongodb/pki"}
  local keyfile_name=${2:-"mongodb-keyfile"}
  local keyfile_path="${keyfile_dir}/${keyfile_name}"

  mkdir -p "$keyfile_dir"

  openssl rand -base64 756 > "$keyfile_path"
  chmod 400 "$keyfile_path"

  echo "Created keyfile at $keyfile_path"
  set_var "MONGODB_KEYFILE_PATH" "${keyfile_path}"

  echo "$keyfile_path"
}