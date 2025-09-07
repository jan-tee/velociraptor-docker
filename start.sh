#!/bin/bash
set -e
export PATH="/opt/velociraptor/bin:$PATH"

BIND_ADDRESS="0.0.0.0"
PUBLIC_PATH="public"
LOG_DIR="/opt/velociraptor/logs"
DATASTORE_LOCATION="/opt/velociraptor/data"
FILESTORE_DIRECTORY="/opt/velociraptor/files"

function env_or_error() {
  VAR_NAME="$1"
  VAR_VALUE="$( eval echo "\$$VAR_NAME" )"
  if [ -z "$VAR_VALUE" ]; then
	echo "Error: Environment variable $VAR_NAME is not set."
	exit 1
  fi
}

# If no existing server config, set it up
if [ ! -f /opt/velociraptor/config/server.config.merge.yaml ]; then
	tempfile="$(mktemp)"

	env_or_error PUBLIC_PATH
	env_or_error VELOX_FRONTEND_HOSTNAME
	env_or_error VELOX_SERVER_URL

	if [ ! -z "${VELOX_TLS_CERT}" ] ; then
		env_or_error VELOX_TLS_KEY
		env_or_error VELOX_TLS_CA
		[ ! -f "${VELOX_TLS_CERT}" ] && echo "Error: TLS certificate file not found." && exit 1
		[ ! -f "${VELOX_TLS_KEY}" ] && echo "Error: TLS key file not found." && exit 1
		[ ! -f "${VELOX_TLS_CA}" ] && echo "Error: TLS CA certificate file not found." && exit 1
	fi

	cat > $tempfile << EOF
Frontend:
  # This is what AGENTS talk to
  public_path: "${PUBLIC_PATH}"
  hostname: "${VELOX_FRONTEND_HOSTNAME}"
  bind_address: "${BIND_ADDRESS}"
  bind_port: 8000
EOF

if [ ! -z "$VELOX_TLS_CERT" ] ; then
  echo "TLS configuration detected, enabling TLS in Velociraptor."
  echo "  tls_certificate: \"${VELOX_TLS_CERT}\"" >> $tempfile
  echo "  tls_key: \"${VELOX_TLS_KEY}\"" >> $tempfile
fi

cat  >> "${tempfile}"  << EOF
API:
  # gRPC based API server
  bind_address: "${BIND_ADDRESS}"
  bind_port: 8001
  bind_scheme: tcp
GUI:
  # This is what ADMINISTRATORS and ANALYSTS use with their browsers
  bind_address: "${BIND_ADDRESS}"
  bind_port: 443
  public_url: "${VELOX_SERVER_URL}"
Monitoring:
  bind_address: "${BIND_ADDRESS}"
Logging:
  output_directory: "${LOG_DIR}"
  separate_logs_per_component: true
Client:
  server_urls:
    - "https://${VELOX_FRONTEND_HOSTNAME}:8000/"
EOF

  if [ ! -z "$VELOX_TLS_CERT" ] ; then
	echo "  use_self_signed_ssl: false" >> $tempfile
	echo "  root_certs: |" >> $tempfile
	sed 's/^/    /' "${VELOX_TLS_CA}" >> $tempfile
  else
    echo "  use_self_signed_ssl: true" >> $tempfile
  fi

cat >> "${tempfile}"  << EOF
Datastore:
  location: "${DATASTORE_LOCATION}"
  filestore_directory: "${FILESTORE_DIRECTORY}"
EOF
    mv $tempfile /opt/velociraptor/config/server.config.merge.yaml
fi

if [ ! -f /opt/velociraptor/config/server.config.yaml ]; then
	# convert YAML to JSON for the merge file. I just like YAML so much better than JSON... despite all the edge cases...
	tempfile=$(mktemp)
	yq -j < /opt/velociraptor/config/server.config.merge.yaml > "${tempfile}"
	/opt/velociraptor/bin/velociraptor \
		config generate \
		> /opt/velociraptor/config/server.config.yaml --merge_file="${tempfile}"
        # sed -i "s#https://localhost:8000/#$VELOX_CLIENT_URL#" server.config.yaml
	sed -i 's#/tmp/velociraptor#.#'g /opt/velociraptor/config/server.config.yaml
	env_or_error VELOX_USER
	env_or_error VELOX_PASSWORD
	env_or_error VELOX_ROLE
	/opt/velociraptor/bin/velociraptor --config /opt/velociraptor/config/server.config.yaml user add "$VELOX_USER" "$VELOX_PASSWORD" --role "$VELOX_ROLE"
	echo "Created initial Velociraptor server config and user."
	echo "To make changes to the server configuration, edit it directly. To re-generate the server configuration and have the merge file applied again, make your changes to the server.config.merge.yaml file and delete server.config.yaml." \
		> /opt/velociraptor/config/README.txt
fi

# Re-generate client config in case server config changed
/opt/velociraptor/bin/velociraptor --config /opt/velociraptor/config/server.config.yaml config client > /opt/velociraptor/config/client.config.yaml

# Repack clients
/usr/local/bin/repack-clients.sh

# Start Velociraptor
exec /opt/velociraptor/bin/velociraptor --config /opt/velociraptor/config/server.config.yaml frontend -v

