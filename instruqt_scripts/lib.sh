#!/usr/bin/env bash
set -euo pipefail

# Globals
APP_FOLDER=/app

# Check that a variable exists
function is_var_set() {
  set +u
  local name=${1?Error: Variable name required}
  local rc=${!name}
  set -u
  [[ -n ${rc} ]]
}

# Verbose output
is_var_set VERBOSE && set -x

# Running in local mode
function is_local_mode() {
  is_var_set LOCAL_TESTING
}

# Running a track test
function is_track_test() {
  is_var_set INSTRUQT_TEST
}

# Running in dev environment
function is_dev() {
  [[ "${ENVIRONMENT_NAME}" == "dev" ]]
}

# Running in prd environment
function is_prd() {
  [[ "${ENVIRONMENT_NAME}" == "prd" ]]
}

# Local testing overrides
if is_local_mode; then
  unset INSTRUQT_TEST
fi

#
# Update AWS CLI
#
function install_aws_cli() {
  # Nothing to do in local mode
  is_local_mode && return 0

  pushd /tmp

  local filename=awscliv2.zip
  echo install_aws_cli...

  # Just in case
  [[ -x /usr/bin/unzip ]] || apt-get -y install unzip
  curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o ${filename}
  unzip ${filename} &> /dev/null
  ./aws/install --update
  aws --version

  popd
}

#
# Pull and extract S3 tgz only in dev
#
# Parameters
# 1. URI
#
function pull_and_extract() {
  # Nothing to do in local mode
  is_local_mode && return 0

  # Only process in dev
  is_dev || return 0

  pushd /tmp

  local uri=${1?Error: Missing URI}
  local tgz=$(basename ${uri})
  echo "pull_and_extract: '${uri}'"

  # Pull it from S3
  if aws --region us-east-1 s3 cp ${uri} .; then
    # Extract it
    if [[ -f ${tgz} ]]; then
      echo Extracting ${tgz}...
      tar -xzvf ${tgz} -C /
    fi
  fi

  popd
}
#
# Determine and store base connection string
#
function set_base_cs() {
  export BASE_CONNECTION_STRING=$(atlas clusters cs describe myAtlasClusterEDU -o json | jq .standardSrv | tr -d \")
  echo set_base_cs: ${BASE_CONNECTION_STRING}
  set_var BASE_CONNECTION_STRING
}

#
# Retrieve the base connection string
#
function get_base_cs() {
  get_var BASE_CONNECTION_STRING
  echo get_base_cs: ${BASE_CONNECTION_STRING}
}

# 
# Prepare the full connection string
# Parameters
# 1. Base Connection String
# 2. Credentials
# 3. DatabaseName
#
function prepare_connection_string() {
  local base=${1?Error: Base Connection String}
  local creds=${2?Error: Missing credentials}
  local dbName=${3?Error: Missing database name}
  local appName="?appName=${INSTRUQT_TRACK_SLUG}"
  echo "prepare_connection_string: base(${base}) dbName(${dbName}) appName(${appName})"

  CONNECTION_STRING=$(echo ${base} | sed -e "s+//+//${creds}@+" -e "s+$+/${dbName}${appName}+")

  set_var CONNECTION_STRING

  cat >>${APP_FOLDER}/.env<<-EOF
export CONNECTION_STRING=${CONNECTION_STRING}
EOF
}

#
# Setup challenge sequence
#
function setup_challenge() {
    # Ensure challenge index is defined
    if ! get_var CHALLENGE_IDX ; then
        CHALLENGE_IDX=1
    else
        CHALLENGE_IDX=$(( CHALLENGE_IDX + 1 ))
    fi
    set_var CHALLENGE_IDX
    echo "setup_challenge: Track(${INSTRUQT_TRACK_SLUG}) Challenge(${INSTRUQT_CHALLENGE_ID}/${CHALLENGE_IDX})"
    is_local_mode && printenv

    return 0
}

# 
# Convenience method to set env variables
#
# First we see if the variable already contains
# a value, otherwise we use the provided optional
# value (if any), lastly we fail if we can't find
# a value.
#
# Parameters
# 1. Name of var that contains value
# 2. Optional: value
#
function set_var() {
  local name=${1?Error: Missing variable name}
  local value=${2:-${!name}}
  echo "set_var: Name(${name}) Value(${value})"

  if ! is_var_set value; then
    echo "Error: value not set for '${name}'"
    exit 1
  fi

  export ${name}="${value}"

  if is_local_mode; then
    echo "export ${name}=\"${value}\"" >> ${AGENT_VARS_FILE}
  else
    agent variable set ${name} "${value}"
  fi
}

#
# Convenience method for testing
# errExit if variable is not found
# 1. Name
#
function get_var() {
  local name=${1?Error: Missing variable name}

  if is_local_mode; then
    [[ -f ${AGENT_VARS_FILE} ]] && source ${AGENT_VARS_FILE}
  else
    local value=$(agent variable get ${name})
    export ${name}=${value}
  fi

  if is_var_set ${name}; then
    echo "get_var: Name(${name}) Value(${!name})"
  else
    echo "get_var: Name(${name}) Value(Not Set)"
    return 1
  fi
}

#
# Setup atlas CLI access in debug
# The name paramter translates into an environment
# variable that should be defined and assigned to this track
#
# Parameters
# 1. Secret name
#
function setup_atlas_cli() {
  local var_name=${1?Error: Missing Name}
  local dst="/root/.config/atlascli/config.toml"

  # Nothing to do when not doing a track test
  is_track_test || return 0

  # Make sure the variable has content
  if ! is_var_set ${var_name}; then
    echo "setup_atlas_cli: Missing content for '${var_name}'"
    exit -1
  fi

  echo "Debug Mode: Creating ${dst} from ${var_name}"

  # Notice the use of 1> so only stdout goes to the file when VERBOSE=1
  {
    echo "${!var_name}"
  } 1> ${dst}
}

#
# Function to set up a lab folder by copying files from a source directory to a destination directory.
# Note: Clears the contents of the destination directory if it already exists. If there is a common directory, it is also copied.
#
# Parameters:
# 1. The basename directory path.
# 2. The type of lab folder to set up (solved or unsolved).
#
function setup_lab_folder() {
  local from=${1?Error: Missing from folder}
  local to=${2?Error: Missing target folder}

  # Create the destination directory if it doesn't exist, clear it otherwise
  [[ ! -d ${to} ]] && mkdir -p ${to} || rm -rf ${to}/*

  # Copy all files and directories
  cp -rv ${from}/. ${to}

  # Copy the common directory if it exists
  local common_dir="${from}/../../common"
  if [[ -d ${common_dir} ]]; then
      cp -rv ${common_dir}/. ${to}
  fi
}

#
# Setup the welcome message depending on the availability of the username
#
function configure_welcome_message() {
  if is_var_set USER_FIRSTNAME; then
    echo "configure_welcome_message: \"${USER_FIRSTNAME}\""
    USER_FIRSTNAME_WELCOME_MSG="Welcome ${USER_FIRSTNAME}!"
    USER_FIRSTNAME_CLOSING_MSG="Thank you ${USER_FIRSTNAME} and please don't forget to rate this lab!"
  else
    USER_FIRSTNAME_WELCOME_MSG="Welcome!"
    USER_FIRSTNAME_CLOSING_MSG="Thanks and please don't forget to rate this lab!"
  fi
  set_var USER_FIRSTNAME_WELCOME_MSG
  set_var USER_FIRSTNAME_CLOSING_MSG
}



# Retrieves the user credentials
#
# Calls get_password to obtain the password.
# Returns the credentials in this format:
# <user>:<password>
#
# Parameters
# 1. User Name
# 2. Base url of the endpoint
# 3. Atlas App Services API key
#
function get_user_creds() {
  local user=${1?Error: Missing Name}
  local base_url=${2?Error: Missing base url}
  local api_key=${3?Error: Missing API_KEY}
  local pwd=$(get_password ${user} ${base_url}/endpoint/creds ${api_key})

  if is_var_set pwd; then
    echo $user:$pwd
  else
    return 1
  fi
}

#
# Get the user's password
# Calls an Atlas app services endpoint.
# Echo's the password
#
# Parameters
# 1. User Name
# 2. Base url of the endpoint
# 3. Atlas App Services API key
#
function get_password() {
  local user=${1?Error: Missing Name}
  local base_url=${2?Error: Missing base url}
  local api_key=${3?Error: Missing API_KEY}
  local url="${base_url}?username=${user}"

  creds=$(curl -s -f --location --globoff --header "apiKey: ${api_key}" ${url})
  local password=$(jq -re '.pwd' <<< ${creds})

  echo ${password}

}

#
# Cleanup challenge sequence
#
function cleanup_challenge() {
    # Get the challenge index
    get_var CHALLENGE_IDX
    echo "cleanup_challenge: Track(${INSTRUQT_TRACK_SLUG}) Challenge(${INSTRUQT_CHALLENGE_ID}/${CHALLENGE_IDX})"
    is_local_mode && printenv

    return 0
}

#
# Resets the CHALLENGE_IDX variable if set
#
# Parameters
# None
#
reset_challenge_idx() {
  set_var CHALLENGE_IDX 0 >/dev/null
}

function extract_embedded_files() {
  local content="${1?Error: Missing base64 content}"
  local expected_checksum="${2?Error: Missing expected SHA256 Checksum}"
  local extract_dir="${3?Error: Missing extraction directory}"

  echo "[INFO] Extracting embedded files to ${extract_dir}..."

  # Create temporary directory for extraction
  local temp_dir
  temp_dir=$(mktemp -d)
  if [[ $? -ne 0 || -z "${temp_dir}" ]]; then
    echo "[ERROR] Failed to create temporary directory"
    return 1
  fi

  # Create temporary file with the base64 content
  local temp_b64="${temp_dir}/embedded_files.b64"
  echo "${content}" > "${temp_b64}"

  if [[ ! -s "${temp_b64}" ]]; then
    echo "[ERROR] Failed to create base64 temporary file or file is empty"
    rm -rf "${temp_dir}"
    return 1
  fi

  # Decode archive with platform detection
  local temp_archive="${temp_dir}/files_archive.tar.gz"

  # Check the OS to determine which base64 decode syntax to use
  if [[ "$(uname)" == "Darwin" ]]; then
    # macOS syntax
    base64 -D -i "${temp_b64}" > "${temp_archive}" || {
      echo "[ERROR] Failed to decode base64 content"
      rm -rf "${temp_dir}"
      return 1
    }
  else
    # Linux syntax
    base64 -d "${temp_b64}" > "${temp_archive}" || {
      echo "[ERROR] Failed to decode base64 content"
      rm -rf "${temp_dir}"
      return 1
    }
  fi

  # Verify checksum with platform detection
  local calculated_checksum
  if command -v sha256sum >/dev/null 2>&1; then
    # Linux
    calculated_checksum=$(sha256sum "${temp_archive}" | awk '{print $1}')
  else
    # macOS
    calculated_checksum=$(shasum -a 256 "${temp_archive}" | awk '{print $1}')
  fi

  if [[ "${calculated_checksum}" != "${expected_checksum}" ]]; then
    echo "[ERROR] Checksum verification failed"
    echo "[ERROR] Expected: ${expected_checksum}"
    echo "[ERROR] Got: ${calculated_checksum}"
    rm -rf "${temp_dir}"
    return 1
  else
    echo "[INFO] Checksum verification passed"
  fi

  # Ensure target directory exists
  mkdir -p "${extract_dir}" || {
    echo "[ERROR] Failed to create extraction directory: ${extract_dir}"
    rm -rf "${temp_dir}"
    return 1
  }

  # Extract archive
  tar -xzvf "${temp_archive}" -C "${extract_dir}" || {
    echo "[ERROR] Failed to extract archive"
    rm -rf "${temp_dir}"
    return 1
  }

  # Clean up
  rm -rf "${temp_dir}"

  echo "[SUCCESS] Files extracted successfully to ${extract_dir}"
  return 0
}

function extract_embedded_files_with_defaults() {
  local extract_dir="${1:-/}"

  # Check if the required environment variables exist
  if [[ -z "${EMBEDDED_FILES:-}" || -z "${EMBEDDED_FILES_SHA256:-}" ]]; then
    echo "[INFO] No embedded files to extract (EMBEDDED_FILES or EMBEDDED_FILES_SHA256 not set)"
    return 0
  fi

  # Call the extract function with environment variables
  extract_embedded_files "${EMBEDDED_FILES}" "${EMBEDDED_FILES_SHA256}" "${extract_dir}" || {
    echo "[ERROR] Failed to extract embedded files"
    exit 1
  }

  return 0
}