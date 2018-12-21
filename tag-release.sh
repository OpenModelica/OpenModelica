#!/bin/bash
# script to tag the release and commit the changes
set -x #echo on

TAG=$1 # the tag
BRANCH=$2 # the maintenance/vXXX branch

echo Tagging with ${TAG} for branch: ${BRANCH}

git fetch origin
git checkout ${BRANCH}

# tag OMCompiler, OMEdit, doc, testsuite, OMNotebook
for dir in OMCompiler OMEdit OMNotebook doc testsuite; do
  cd $dir
  echo Tagging ${dir} to ${TAG}
  git checkout ${BRANCH}
  # update common to master if it exists!
  [ -d ./common ] && cd common && git checkout master && cd .. &&  git add common
  git commit --allow-empty -m "${TAG}"
  git tag -a -m "${TAG}" ${TAG}
  git push --set-upstream origin ${BRANCH}
  git push --tags
  git pull
  git fetch --tags
  echo $PWD
  cd ..
done

# update everything else to master!
for dir in OMPlot OMOptim OMSimulator OMShell; do
  cd $dir
  echo Updating ${dir} to master
  git checkout master
  git pull
  git fetch --tags
  cd ..
done


# update common to master!
cd common && git checkout master && cd ..
git add common

echo Back on $PWD

# add all the submodules we need!
git add OMCompiler OMEdit OMNotebook doc testsuite OMPlot OMOptim OMSimulator OMShell

# tag the glue project
git commit --allow-empty -m "${TAG}"
git tag -a -m "${TAG}" ${TAG}
git push --set-upstream origin ${BRANCH}
git push --tags
git pull
git fetch --tags

# check if all is fine
echo OpenModelica glue project tag
git describe --match "v*.*" --always
echo OpenModelica submodule tags
git submodule foreach "git describe --match "v*.*" --always"

