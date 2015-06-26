# How to contribute to the OpenModelica Compiler

Note that your contributions are assumed to follow the [contributor license agreement](https://openmodelica.org/osmc-pl/osmc-pl-1.2.txt) (which means the [Open Source Modelica Consortium](https://openmodelica.org) holds the copyright).

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

Note that [@OpenModelica-Hudson](https://github.com/OpenModelica-Hudson/)
will rebase your changes on top of master, which means that if you create
new commits on top of your topic branch, your changes might be hard to
merge with the master. It also means that if you do not base your commits
on origin/master, you might be adding your commits two times if you merge
again (the commits Hudson rebased and the commits that you made, plus an
empty merge commit).

Commits that are pushed to this repository should pass the [test suite](https://github.com/OpenModelica/OpenModelica-testsuite),
and [@OpenModelica-Hudson](https://github.com/OpenModelica-Hudson/) makes sure this is true.

Developers can trigger the Hudson job [OpenModelica hudson job](https://test.openmodelica.org/hudson/job/OpenModelica_TEST_PULL_REQUEST/build?delay=0sec)
after creating a pull request to trigger a build+test+push from a pull
request (or directly from the developer's own branch). The Hudson job
refuses to build any hash other than the latest hash in the pull request,
which automatically syncs to the fork. It is thus important that if the
pull request is finished, no more commits are pushed unless they fix
something.

All commits should adhere to the following simple guidelines (the Hudson
job checks some of these restrictions, and will automatically reject your
submission if the reviewer missed it):

* Use UTF-8 as file encoding.
* No trailing whitespace in text-files.
* No binary files added (object files, etc). Images are fine for icons in the graphical clients. Note that images should use vector graphics (SVG) as far as it is possible to do so.
* No automatically generated code or build artifacts added. This includes documentation such as Doxygen.
* No adding+deleting the same file or line (debug lines/etc). Do an interactive rebase to squash the commits into one.
* If you have many added+deleted files/etc - squash all commits into a single commit instead.
* For OpenModelica-testsuite: Any added or modified reference file needs to use [filterSimulationResults](https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/scripting_api.html#filtersimulationresults) to create a file with a minimal number of trajectories and output points in order to reduce the file size. It is often possible to reduce a file from 20MB to 10kB without significant losses.
