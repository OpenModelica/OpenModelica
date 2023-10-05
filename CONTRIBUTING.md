# How to contribute to the OpenModelica Compiler

Note that your contributions are assumed to follow the [contributor license agreement](https://openmodelica.org/osmc-pl/osmc-pl-1.8.txt) (which means the [Open Source Modelica Consortium](https://openmodelica.org) holds the copyright).

Contributions are primarily in the form of pull requests.
To learn more about [collaboration, see the github articles](https://help.github.com/categories/collaborating/).
Fork the OpenModelica repositories into your user account, create a
topic branch (not master) which you make your changes in and push to
your own fork. The reason for the topic branch is to isolate your changes.
If you want to fix two different things, create two different branches
to make the changes easier to review.

Rebase your commits on top of master as often as possible. Do not introduce
merge commits in your pull requests unless necessary. There are many
alternatives available, but fetch and rebase works well on a topic branch.

```bash
git pull --rebase
git pull && git rebase
git fetch origin && git rebase origin/master
```

Commits that are pushed to this repository should pass the [test suite](https://github.com/OpenModelica/OpenModelica-testsuite),
and our CI server [@OpenModelica-Jenkins](https://test.openmodelica.org/jenkins/) makes sure this is true.

Pull requests are automatically checked:
* against the testsuite by Jenkins CI
* for contribution agreement signature

When creating the PR, if needed, add labels: "CI/Build MINGW" or "CI/Build OSX" to test the build on Windows and MacOS.
One of our developers will review and merge the PR.

All commits should adhere to the following simple guidelines (the Jenkins job checks some of these restrictions, and will not pass your submission):

* Use UTF-8 as file encoding.
* No trailing whitespace in text-files.
* No binary files added (object files, etc). Images are fine for icons in the graphical clients. Note that images should use vector graphics (SVG) as far as it is possible to do so.
* No automatically generated code or build artifacts added. This includes documentation such as Doxygen.
* No adding+deleting the same file or line (debug lines/etc). Do an interactive rebase to squash the commits into one.
* If you have many added+deleted files/etc - squash all commits into a single commit instead.
* For OpenModelica-testsuite: Any added or modified reference file needs to use [filterSimulationResults](https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/scripting_api.html#filtersimulationresults) to create a file with a minimal number of trajectories and output points in order to reduce the file size. It is often possible to reduce a file from 20MB to 10kB without significant losses.
* Use short lines in commit messages in order for github and git tools to display properly in terminal / web GUI.

## Working with the OpenModelica/OMCompiler/3rdParty submodule

If you need to make changes to OMCompiler-3rdParty the procedure is as follows:
* push to a branch in OMCompiler-3rdParty (ask us for access via OpenModelica mailing list)
* make a PR to OpenModelica glue project with OpenModelica/OMCompiler/3rdParty submodule pointing at your commit from the pushed branch in OMCompiler-3rdParty

After Jenkins checks that all is OK a developer will:
* **reset** (or restart, or **merge**, if there were other commits added to OMCompiler-3rdParty since you started) the OMCompiler-3rdParty master branch so the new HEAD contains the HEAD commit of the branch
* merge the PR in the OpenModelica glue project
* delete the branch in the OMCompiler-3rdParty

## Bootstrapping sources

Sometimes one would need to update the bootstrapping sources to add new features to the MetaModelica compiler. The bootstrapping sources are stored at: [OMBootstrapping](https://github.com/OpenModelica/OMBootstrapping.git), just make a PR for it with the contents of OMCompiler/Compiler/boot/build.
