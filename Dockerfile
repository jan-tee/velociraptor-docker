FROM ubuntu:24.04 AS builder
LABEL version="Velociraptor v0.7.5"
LABEL description="Velociraptor server in a Docker container"
LABEL maintainer="Wes Lambert, @therealwlambert"

RUN apt-get update && \
    apt-get install -y curl wget jq zip

ARG TAG
RUN echo $TAG

# Create temporary directories for Velo binaries, get & move binaries into place
RUN mkdir -p /opt/velociraptor && \
    for i in linux mac windows; do mkdir -p /opt/velociraptor/$i; done && \
    RELEASE_DATA=$(curl -Ls -o /tmp/release "https://api.github.com/repos/Velocidex/velociraptor/releases/tags/${TAG}") && \
    WIN_EXE=$(jq -r 'limit(1 ; ( .assets[].browser_download_url | select ( contains("windows-amd64.exe") )))' /tmp/release) && \
    WIN_MSI=$(jq -r 'limit(1 ; ( .assets[].browser_download_url | select ( contains("windows-amd64.msi") )))' /tmp/release) && \
    LNX_BIN=$(jq -r 'limit(1 ; ( .assets[].browser_download_url | select ( contains("linux-amd64") )))' /tmp/release) && \
    MAC_BIN=$(jq -r 'limit(1 ; ( .assets[].browser_download_url | select ( contains("darwin-amd64") )))' /tmp/release) && \
    curl -Ls -o /opt/velociraptor/linux/velociraptor "${LNX_BIN}" && \
    curl -Ls -o /opt/velociraptor/mac/velociraptor_client "${MAC_BIN}" && \
    curl -Ls -o /opt/velociraptor/windows/velociraptor_client.exe "${WIN_EXE}" && \
    curl -Ls -o /opt/velociraptor/windows/velociraptor_client.msi "${WIN_MSI}"
    
FROM ubuntu:24.04

RUN apt update && \
    apt install -y tini yq jq && \
    apt-get clean && \
    rm -rfv /var/lib/apt/lists/*

# create config dir
RUN for p in config linux mac windows logs data files certs; do mkdir -p /opt/velociraptor/$p; done

WORKDIR /opt/velociraptor 

COPY ./start.sh /usr/local/bin/
COPY ./repack-clients.sh /usr/local/bin/
RUN chmod 0755 /usr/local/bin/*.sh

COPY --from=builder /opt/velociraptor/linux/velociraptor bin/velociraptor
COPY --from=builder /opt/velociraptor/linux/velociraptor clients-raw/linux/velociraptor_client
COPY --from=builder /opt/velociraptor/mac/velociraptor_client clients-raw/mac/velociraptor_client
COPY --from=builder /opt/velociraptor/windows/velociraptor_client* clients-raw/windows/
RUN chmod a+x /opt/velociraptor/bin/velociraptor

ENTRYPOINT ["tini", "/usr/local/bin/start.sh"]