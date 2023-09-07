#!/usr/bin/env python3

from subprocess import call
from github import Github
import os

gh_auth = os.environ["GITHUB_AUTH"]
g = Github(gh_auth)
om = g.get_repo("OpenModelica/OpenModelica")
fout = open("githubreleases.md", "w", encoding="utf-8")

for release in om.get_releases():
    if release.draft:
        continue
    if release.tag_name in [
      "v1.9.5",
      "v1.9.4",
      "v1.9.3"
    ]:
        continue
    fout.write("# Release Notes for %s" % release.title)
    fout.write("\n")
    fout.write(release.body)
    fout.write("\n")
    print(release.title)
fout.close()
call(["pandoc", "--wrap=none", "--standalone", "-f", "gfm", "-t", "rst", "--shift-heading-level-by=3", "-o", "githubreleases.tmp.rst", "githubreleases.md"])
with open("githubreleases.tmp.rst", "r", encoding="utf-8") as fin:
    with open("githubreleases.tmp2.rst", "w", encoding="utf-8") as fout:
        fout.write('''Major OpenModelica Releases
"""""""""""""""""""""""""""

This Appendix lists the most important OpenModelica releases and a brief description of their contents.
Right now versions from 1.3.1 to %s are described.

''' % om.get_latest_release().tag_name)
        fout.write(fin.read())
        fout.write("\n")
        fout.write(".. include :: tracreleases.inc")
os.rename("githubreleases.tmp2.rst", "githubreleases.rst")
os.remove("githubreleases.tmp.rst")
