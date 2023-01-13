FROM ubuntu:22.04
LABEL version="Velociraptor v0.6.4"
LABEL description="Velociraptor server in a Docker container"
LABEL maintainer="Wes Lambert, @therealwlambert"

COPY ./entrypoint .
RUN chmod +x entrypoint && \
    apt-get update && \
    apt-get install -y curl wget jq zip

# Create temporary directories for Velo binaries, get & move binaries into place
RUN mkdir -p /opt/velociraptor && \
    for i in linux mac windows; do mkdir -p /opt/velociraptor/$i; done && \
    WINDOWS_EXE=$(curl -s https://api.github.com/repos/velocidex/velociraptor/releases/latest | jq -r 'limit(1 ; ( .assets[].browser_download_url | select ( contains("windows-amd64.exe") )))')  && \
    WINDOWS_MSI=$(curl -s https://api.github.com/repos/velocidex/velociraptor/releases/latest | jq -r 'limit(1 ; ( .assets[].browser_download_url | select ( contains("windows-amd64.msi") )))') && \
    LINUX_BIN=$(curl -s https://api.github.com/repos/velocidex/velociraptor/releases/latest | jq -r 'limit(1 ; ( .assets[].browser_download_url | select ( contains("linux-amd64") )))') && \
    MAC_BIN=$(curl -s https://api.github.com/repos/velocidex/velociraptor/releases/latest | jq -r 'limit(1 ; ( .assets[].browser_download_url | select ( contains("darwin-amd64") )))') && \
    wget -O /opt/velociraptor/linux/velociraptor "$LINUX_BIN" && \
    wget -O /opt/velociraptor/mac/velociraptor_client "$MAC_BIN" && \
    wget -O /opt/velociraptor/windows/velociraptor_client.exe "$WINDOWS_EXE" && \
    wget -O /opt/velociraptor/windows/velociraptor_client.msi "$WINDOWS_MSI"
    
WORKDIR /velociraptor 

# create config dir
RUN mkdir -p /velociraptor/config

# Move binaries into place
RUN \
    cp /opt/velociraptor/linux/velociraptor ./velociraptor && \
    chmod +x velociraptor && \
    mkdir -p /velociraptor/clients/linux && \
    mv -vf /opt/velociraptor/linux/velociraptor /velociraptor/clients/linux/velociraptor_client && \
    mkdir -p /velociraptor/clients/mac && \
    mv -vf /opt/velociraptor/mac/velociraptor_client /velociraptor/clients/mac/velociraptor_client && \
    mkdir -p /velociraptor/clients/windows && \
    mv -vf /opt/velociraptor/windows/velociraptor_client* /velociraptor/clients/windows/

# Clean up 
RUN apt-get remove -y --purge curl wget && \
    apt-get clean && \
   rm -rfv /opt/velociraptor

CMD ["/entrypoint"]
