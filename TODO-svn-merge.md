# TODO after the SVN merge

A few directories and tests were removed because they were very big.
In particular ReferenceFiles, flattening tests, and tests using some
large total model of a library.

Most of these can be fixed by using the new libraries (more libraries are included).
By doing a checkModel instead of a huge flattening test that just causes
large diffs when changing the frontend.

- Reference files should be put in the root directory with an environment
variable passing the path to each test case (started: msl32 files were moved).
- Reference files should in no case be larger than 1MB.

## List of stupid directories

- flattening/libraries/msl22
- flattening/libraries/msl22/modelicaAdditions
- flattening/libraries/msl31
- flattening/libraries/3rdParty/HumMod
