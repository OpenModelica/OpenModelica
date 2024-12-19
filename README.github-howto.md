# Usual GitHub workflow

This is a short crash course on how to use git and github to create PRs (pull requests) for the OpenModelica repository (or any other repository).
Of course you can find your own workflow but you should make sure you always start from `origin/master`, not your own remote `master` or previous branches which where already merged in the `origin/master`.

Variables which are specific to each user are in all caps: YOUR_REMOTE, YOUR_GITHUB_ACCOUNT, YOUR_NEW_BRANCH, YOUR_FILE, YOUR_DIRECTORY.

## Clone the repository

First you clone the repo and set your remote:
```
# clone the original repo
git clone https://github.com/OpenModelica/OpenModelica.git --recursive
cd OpenModelica
# add your repository on github (I named it YOUR_REMOTE) as a new remote (besides origin) - one of the 2 options below
# 1. for a https URL as below you need to use a github token, if you do not have one see the ssh keys below
git remote add YOUR_REMOTE https://github.com/YOUR_GITHUB_ACCOUNT/OpenModelica.git
# 2. if you instead have ssh keys setup for github use the git@ scheme instead:
git remote add YOUR_REMOTE git@github.com:YOUR_GITHUB_ACCOUNT/OpenModelica.git

```

## Update your local repo before each change

Then you can just do this for each change, update your `master` from `origin`. You can reuse this script if you want or do your own.

```
#!/bin/bash -x
git checkout master
git fetch origin && git submodule foreach git fetch origin
git pull --recurse-submodules && git submodule update --init --recursive
git submodule foreach --recursive "git checkout master"
git submodule foreach --recursive "git pull"
git submodule update --init --recursive
# this is just to show some status of the update
git status
git submodule status --recursive
```

## Make your own branch starting from master

Now make your own branch from your updated master:

```
git checkout master
git checkout -b YOUR_NEW_BRANCH
```

## Change your code and do your PR

Change what you want in the code and add only the files you need to change.
Make sure you do not add old submodules for OMCompiler/3rdParty, OMSimulator, etc.

```
git add YOUR_FILE
git add YOUR_DIRECTORY

# now commit your change locally with a nice message (or use your editor for that without -m)
git commit -m "meaningful change message"

# now you push YOUR_NEW_BRANCH to your repository YOUR_REMOTE on github
git push YOUR_REMOTE YOUR_NEW_BRANCH

# this will give you a link which you can use to create a PR on github web interface
# looks something like this:
# remote:
# #remote: Create a pull request for 'YOUR_NEW_BRANCH' on GitHub by visiting:
# remote:      https://github.com/YOUR_GITHUB_ACCOUNT/OpenModelica/pull/new/YOUR_NEW_BRANCH
# remote:
```

After your PR is merged you can delete YOUR_BRANCH, update your repo from origin/master (see above) and make a new branch (see above).

# Update YOUR_BRANCH with the latest from origin/master

If you need to update your branch with some recent changes from master (to fix conflicts) before or after you push your PR you can do:

```
# switch to your branch if not already there
git checkout YOUR_NEW_BRANCH

# commit your changes to be sure you do not lose any
git add YOUR_FILE
git add YOUR_DIRECTORY

# now commit your change locally with a nice message (or use your editor for that without -m)
git commit -m "meaningful change message"

# now switch to master and update master to origin/master (see the script above)
# then switch back to your branch
git checkout YOUR_NEW_BRANCH

# rebase the changes from master
git rebase master

# fix any conflicts you might have and do git add / git rebased --continue until finished
```



