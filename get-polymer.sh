#!/bin/bash
#
# Download polymer via GitHub
#
mkdir ./war/polymer_local; cd ./war/polymer_local
git clone https://github.com/Polymer/tools.git
./tools/bin/pull-all.sh
