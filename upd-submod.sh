#! /usr/bin/env bash
git submodule foreach --recursive "git checkout master"
# To update; you will need to merge each submodule, but your changes will remain
git submodule foreach --recursive "git pull"
# Running master on all submodules might lead to build errors
# so use this to make sure you force all submodules to the commits
# from the OpenModelica glue project which are properly tested
git submodule update --force --init --recursive

rm -rf OMCompiler/3rdParty/Ipopt
rm -rf OMPlot/qwt