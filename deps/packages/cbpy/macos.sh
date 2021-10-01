#!/bin/bash -ex
MINIFORGE_VERSION=4.10.3-5

script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
pkgs="$script_dir/conda-pkgs"

WD=$(mktemp -d)
pushd $WD

curl --fail -Lo "${WD}/cbdep" https://packages.couchbase.com/cbdep/1.0.4/cbdep-1.0.4-darwin-$(uname -m|awk '{print tolower($0)}')
chmod a+x "${WD}/cbdep"
"${WD}/cbdep" install -d . miniforge3 ${MINIFORGE_VERSION}

. ./miniforge3-${MINIFORGE_VERSION}/bin/activate
conda install -y conda-build conda-pack conda-verify
([ "$(ls -A ${pkgs}/all)" ] && conda build --output-folder "./conda-pkgs" "${pkgs}/all/*" || :)
([ "$(ls -A ${pkgs}/stubs)" ] && conda build --output-folder "./conda-pkgs" "${pkgs}/stubs/*" || :)

conda create -y -n cbpy
conda activate cbpy
conda install -y -c "./conda-pkgs" $(grep -e "^[A-Za-z0-9\-]*=" ${script_dir}/cb-dependencies.txt | tr "\n" ' ') $(grep -e "^[A-Za-z0-9\-]*=" /cb-stubs.txt | tr "\n" ' ')
conda update -y -c "./conda-pkgs" --update-all
conda list
