#!/bin/bash
mkdir -p "/opt/velociraptor/clients/"
cd /opt/velociraptor || exit 1

timestamp=$(date +'%Y%m%d-%H%M%S')

if [ -f clients/client.config.yaml ] && cmp -s config/client.config.yaml clients/client.config.yaml ; then
  echo "Client config unchanged, skipping repack"
  exit 0
fi

# preserve old config and clients
mkdir -p "/opt/velicoraptor/clients/${timestamp}"
for f in clients/* ; do
  if [ -f "$f" ]; then
    mv -f "$f" "/opt/velicoraptor/clients/${timestamp}/"
  fi
done

# save new config
cp -f config/client.config.yaml clients/client.config.yaml

# generate agents
echo "Building Linux DEB client package"
velociraptor debian client \
  --config config/client.config.yaml \
  --output clients/

echo "Building Linux RPM client package"
velociraptor rpm client \
  --config config/client.config.yaml \
  --output clients/

echo "Building Windows MSI client package"
velociraptor config repack \
  --msi clients-raw/windows/velociraptor_client.msi \
  config/client.config.yaml \
  clients/velociraptor_client.msi

echo "Repacking Linux client"
velociraptor config repack \
  --exe clients-raw/linux/velociraptor_client \
  config/client.config.yaml \
  clients/velociraptor_client_linux

echo "Repacking Mac client"
velociraptor config repack \
  --exe clients-raw/mac/velociraptor_client \
  config/client.config.yaml \
  clients/velociraptor_client_mac

echo "Repacking Windows client"
velociraptor config repack \
  --exe clients-raw/windows/velociraptor_client.exe \
  config/client.config.yaml \
  clients/velociraptor_client_windows.exe
