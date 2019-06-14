#!/bin/bash

ENV_NAME=$1

if [ ! $ENV_NAME ]; then
    echo "[ERROR] Please provide environment name as only argument."
    echo "[ERROR]  $ ./install.sh cdds-env-r20190531"
    exit
fi

if [ ! $SVN_CDDS_USERNAME ]; then
    echo "[ERROR] Must set SVN_CDDS_USERNAME environment variable."
    exit
fi

if [ ! $SVN_CDDS_PASSWORD ]; then
    echo "[ERROR] Must set SVN_CDDS_PASSWORD environment variable."
    exit
fi


TOP_DIR=cdds-env
CDDS_TAG_URL=https://code.metoffice.gov.uk/svn/cdds/main/tags/1.1.0
ENVS_REPO=https://github.com/cedadev/esgf-conda-envs
REQUIRED_PACKAGES="hadsdk mip_convert cdds_configure cdds_convert cdds_prepare cdds_qc"

GWS=/gws/smf/j04/cmip6_prep

rm -fr $TOP_DIR
mkdir -p $TOP_DIR
cd $TOP_DIR/

SETUP_SCRIPT=$PWD/setup_cdds_env.sh
export JASPY_BASE_DIR=$GWS/jaspy_base
mkdir -p $JASPY_BASE_DIR

git clone https://github.com/cedadev/jaspy-manager
cd jaspy-manager/

bin/add-envs-repo.sh $ENVS_REPO
bin/install-jaspy-env.sh $ENV_NAME

env_dir=$(find $JASPY_BASE_DIR -type d -name $ENV_NAME)
parent_dir=$(dirname $(dirname $env_dir))

cd ../

# Create setup script
rm -f $SETUP_SCRIPT
echo "cd $PWD" >> $SETUP_SCRIPT
echo "export PATH=$parent_dir/bin:\$PATH" >> $SETUP_SCRIPT
echo "source activate $ENV_NAME" >> $SETUP_SCRIPT
echo "export PYESSV_ARCHIVE_HOME=$PWD/cc-vocab-cache/pyessv-archive-eg-cvs" >> $SETUP_SCRIPT

# Pull the CDDS source from SVN
svn checkout --non-interactive --trust-server-cert --username $SVN_CDDS_USERNAME --password $SVN_CDDS_PASSWORD $CDDS_TAG_URL

# Keep the tag and symlink "cdds" to it
tag=$(basename $CDDS_TAG_URL)
ln -s $tag cdds

# Activate the conda env before pip installing
source $SETUP_SCRIPT

# Pip install required packages
for pkg in $REQUIRED_PACKAGES; do
    cd cdds/$pkg/
    echo "[INFO] Pip installing: cdds/$pkg"
    $env_dir/bin/pip install .
    cd ../../
done

echo "Get started with: "
echo " $ source $SETUP_SCRIPT"

echo
echo "Test with: "
echo " $ python -c 'import cdds_convert'"


