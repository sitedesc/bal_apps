#!/bin/bash -xv
pushd /home/franck/dev/srv_opportunity
rm -f /home/franck/dev/srv_opportunity/entrypoint.sh
rm -f /home/franck/dev/srv_opportunity/docker-compose.override.yml
git checkout Dockerfile
pushd /home/franck/dev/dev_it
bal run /home/franck/dev/dev_it -- srv_opportunity ./modules/srv_opportunity/releaseConfiguration.json
popd
popd
