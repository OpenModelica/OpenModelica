# OpenModelica libraries

## How to add a new library needed by the testsuite

Run `update.py` from this directory, it writes the generated files to the current working directory.

1. Add the library to the `testing` dict in [update.py](./update.py)
2. Regenerate the testsuite index files `index.mos`/`index.json`: `./update.py --test ""`
3. Regenerate the install index files `install-index.mos`/`install-index.json`: `./update.py install-`.
   Only needed when you changed the `installed` dict, otherwise this just bumps the time stamp.
4. Commit the changes to a new PR.
5. To install the library do run `cmake --build build_cmake --target testsuite-depends`. This uses the
   installed `omc`, so OpenModelica has to be built and installed first.

## The libraries shipped with an installation

The libraries listed in the `installed` dict in [update.py](./update.py) are downloaded into a package
cache that is shipped with the installation, so that `installPackage` works without network access.
They are part of the testsuite set as well. Build them with

```sh
cmake --build build_cmake --target omlibrary
```

This needs an already installed `omc`.
The cache is staged in the build tree and copied to `<prefix>/share/omlibrary/cache` by the `install` target, or by `cmake --install build_cmake --component omlibrary` if you only want to install the cache.
