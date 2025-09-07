#!/bin/bash
for p in linux mac windows; do
  mkdir -p "/opt/velociraptor/clients/${p}"
done

cd /opt/velociraptor || exit 1

echo "Repacking Linux client"

velociraptor config repack \
  --exe clients-raw/linux/velociraptor_client \
  config/client.config.yaml \
  clients/linux/velociraptor_client
echo "Repacking Mac client"

velociraptor config repack \
  --exe clients-raw/mac/velociraptor_client \
  config/client.config.yaml \
  clients/mac/velociraptor_client

echo "Repacking Windows client"
velociraptor config repack \
  --exe clients-raw/windows/velociraptor_client.exe \
  config/client.config.yaml \
  clients/windows/velociraptor_client.exe
