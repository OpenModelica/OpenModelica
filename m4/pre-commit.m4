if test -e .git; then
  GIT_DIR=`git rev-parse --git-dir`
  if test ! -f "$GIT_DIR/hooks/pre-commit"; then
    ln -s "`pwd`/common/pre-commit.sh" "$GIT_DIR/hooks/pre-commit"
    AC_MSG_NOTICE([OpenModelica pre-commit hook has been installed])
  fi
fi
