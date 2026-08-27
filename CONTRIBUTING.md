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

When creating the PR, if needed, add labels: "CI/Build MSYS2-UCRT64" or "CI/Build OSX" to test the build on Windows and macOS.
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

`bomc`, the compiler used to translate the MetaModelica sources of `omc`, is built from
pre-translated C sources instead of from the `.mo` files themselves. Those sources live in
the [OMBootstrapping](https://github.com/OpenModelica/OMBootstrapping.git) repository,
checked out as the submodule `OMCompiler/Compiler/boot/bomc`. They have to be refreshed
whenever `bomc` becomes too old to translate the current `OMCompiler/Compiler/*.mo`, for
example after adding MetaModelica syntax or new builtin functions.

From a configured CMake build directory:

```bash
cmake --build build_cmake --target update-bootstrap-sources
```

This builds `omc`, translates the compiler a second time with `OPENMODELICA_BACKEND_STUBS=1`
(so that the source file names baked into the generated C are basenames rather than the
absolute paths of the tree it was built in) and copies the result into the submodule working
tree. The result is reproducible: regenerating it from a different checkout, or at a
different time, produces the same bytes. Use the `generate-bootstrap-sources` target instead
to produce the sources under `<build_dir>/OMCompiler/Compiler/bootstrap-sources/` without
touching the submodule.

Afterwards:

* commit the changes in `OMCompiler/Compiler/boot/bomc` and make a PR against OMBootstrapping
* re-run `cmake` and rebuild to verify that `bomc` builds from the new sources
* once merged, make a PR against OpenModelica moving the submodule to the new commit

`bootstrap-sources/build/FakeBoostrappingExternals.c` is hand written and is left alone by
the update. If the refreshed sources reference external C functions that `bomc` does not
link, add stubs for them there.

`bootstrap-sources/Makefile.sources` is not regenerated. It is only read by the autotools
`bootstrap-from-tarball`; the CMake build of `bomc` globs `bootstrap-sources/build/*.c`.
