#!/bin/bash -xv

# Vérification du nombre de paramètres
if [ "$#" -ne 1 ]; then
    echo "Synopsis : $0 <target_source_distrib_absolute_directory_path>"
    echo "This script creates a source distribution in the target directory given as parameter (this directory should be writable and its abolute path given)."
    echo "This distribution can then be executed running bal run in <target_source_distrib_absolute_directory_path>/bal_apps/apps/chatapi/srv_opportunity as described in the README."
    exit 1
fi

TARGET_DISTRIB_DIR=$1
pushd `dirname $0`
cp -r ../srv_opportunity $TARGET_DISTRIB_DIR/.
rm -rf ./target
rm -rf $TARGET_DISTRIB_DIR/srv_opportunity/responses/* $TARGET_DISTRIB_DIR/srv_opportunity/tools $TARGET_DISTRIB_DIR/srv_opportunity/Dependencies.toml $TARGET_DISTRIB_DIR/srv_opportunity/Config.toml $TARGET_DISTRIB_DIR/srv_opportunity/tmp/*
mkdir -p $TARGET_DISTRIB_DIR/modules
cp -r ../../../modules/teams $TARGET_DISTRIB_DIR/modules/.
rm -rf $TARGET_DISTRIB_DIR/modules/teams/target $TARGET_DISTRIB_DIR/modules/teams/Config.toml $TARGET_DISTRIB_DIR/modules/teams/tests/Config.toml $TARGET_DISTRIB_DIR/modules/teams/Dependencies.toml $TARGET_DISTRIB_DIR/modules/teams/.vscode $TARGET_DISTRIB_DIR/modules/teams/Secrets*
popd