# velociraptor-docker

Run [Velocidex Velociraptor](https://github.com/Velocidex/velociraptor) server with Docker

## Installation

 - Ensure [docker-compose](https://docs.docker.com/compose/install/) is installed on the host
 - `git clone https://github.com/jan-tee/velociraptor-docker`
 - `cd velociraptor-docker`
 - Change credential values in `.env` as desired
 - `docker-compose up` (or `docker-compose up -d` for detached)
 - Access the Velociraptor GUI via `https://\my.server.url`.

## Notes

Linux, Mac, and Windows binaries are located in `/opt/velociraptor/clients`, which should be mapped to the host in the if using `docker-compose`.  There should also be versions of each automatically repacked based on the server configuration.

Once started, edit `server.config.yaml` in `/velociraptor`, then run `docker-compose down/up` for the server to reflect the changes.

## Notes on server.config.merge.yaml

 - You can make persistent changes to either `server.config.merge.yaml` (which will be merged when auto-generating `server.config.yaml`) or `server.yaml`.
 - Auto-generation will only be performed when `server.config.yaml` does not exist.
 - This allows you to re-generate `server.config.yaml` to sane values whenever you want, and upgrade to later versions of Velociraptor without losing track of customizations
