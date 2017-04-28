#!/bin/bash

set +o histexpand

# BOOTSTRAP_URL="$(hostname -I)"
BOOTSTRAP_URL=$1
DCOS_DOWNLOAD_URL=$2
DCOS_PASSWORD_HASH='$6$rounds=656000$83725EIL6U0tE/PU$1cJ9wGZ47q2QTQEZbMWK.uuXyB5CUirWRfBlQTDMnFsvH5l5sI50tdlH7TKYTzaPdVbsxix9NWrim1.y3Cfwf/' # Passw0rd

cd /var/tmp

mkdir -p /var/tmp/genconf

cat <<EOF > "/var/tmp/genconf/config.yaml"
---
bootstrap_url: http://${BOOTSTRAP_URL}:80
cluster_name: 'dcos'
exhibitor_storage_backend: static
ip_detect_filename: /genconf/ip-detect
master_discovery: static
master_list:
- 172.16.0.10
resolvers:
- 8.8.8.8
- 8.8.4.4
oauth_enabled: 'false'
telemetry_enabled: 'false'
superuser_username: 'admin'
superuser_password_hash: '${DCOS_PASSWORD_HASH}'
EOF

cat <<'EOF' > "/var/tmp/genconf/ip-detect"
#!/usr/bin/env bash
set -o nounset -o errexit
ip route get 1 | awk '{print $NF;exit}'
EOF

# curl -O https://downloads.dcos.io/dcos/stable/dcos_generate_config.sh
curl -O "${DCOS_DOWNLOAD_URL}"

sudo bash dcos_generate_config.sh

sudo docker run -d -p 80:80 -v /var/tmp/genconf/serve:/usr/share/nginx/html:ro nginx:alpine