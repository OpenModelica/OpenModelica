if test -d .git && test ! -f .git/hooks/pre-commit; then
  ln -s ../../common/pre-commit.sh .git/hooks/pre-commit
  AC_MSG_NOTICE([OpenModelica pre-commit hook has been installed])
fi
