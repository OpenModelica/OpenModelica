#!/bin/sh
# A git hook script to find and fix trailing whitespace in your commits. Bypass
# it with the --no-verify option to git-commit.

# detect platform
platform="win"
uname_result=`uname`
if [ "$uname_result" = "Linux" ]; then
  platform="linux"
elif [ "$uname_result" = "Darwin" ]; then
  platform="mac"
fi

# change IFS to ignore filename's space in |for|
IFS="
"

# remove trailing whitespace in modified lines
for line in `git diff --check --cached | sed '/^[+-]/d'` ; do
  # get file name
  if [ "$platform" = "mac" ]; then
    file="`echo $line | sed -E 's/:[0-9]+: .*//'`"
    line_number="`echo $line | sed -E 's/.*:([0-9]+).*/\1/'`"
  else
    file="`echo $line | sed -r 's/:[0-9]+: .*//'`"
    line_number="`echo $line | sed -r 's/.*:([0-9]+).*/\1/'`"
  fi

  # since $file in working directory isn't always equal to $file in index,
  # we backup it; thereby we can add our whitespace fixes without accidently
  # adding unstaged changes
  backup_file="${file}.working_directory_backup"
  cat "$file" > "$backup_file"
  git checkout -- "$file" # discard unstaged changes in working directory

  # remove trailing whitespace in $file (modified lines only)
  if [ "$platform" = "win" ]; then
    # in windows, `sed -i` adds ready-only attribute to $file (I don't kown why), so we use temp file instead
    if grep -q "[.]mo$" "$file"; then
      sed  -e "${line_number}s/[[:space:]]*$//" -e "${line_number}s/$(printf '\t')/  /" "$file" > "${file}.bak"
    else
      sed  -e "${line_number}s/[[:space:]]*$//" "$file" > "${file}.bak"
    fi
    mv -f "${file}.bak" "$file"
  elif [ "$platform" = "mac" ]; then
    sed -i "" "${line_number}s/[[:space:]]*$//" "$file"
    if grep -q "[.]mo$" "$file"; then
      sed -i "" "${line_number}s/$(printf '\t')/  /" "$file"
    fi
  else
    sed -i "${line_number}s/[[:space:]]*$//" "$file"
    if grep -q "[.]mo$" "$file"; then
      sed -i "${line_number}s/$(printf '\t')/  /" "$file"
    fi
  fi
  git add "$file" # to index, so our whitespace changes will be committed

  # restore unstaged changes in $file from its working directory backup, fixing
  # whitespace that we fixed above
  sed "${line_number}s/[[:space:]]*$//" "$backup_file" > "$file"
  rm "$backup_file"

  [ "$platform" = "mac" ] || e_option="-e" # mac does not understand -e
  /bin/echo $e_option "Removed trailing whitespace in \033[31m$file\033[0m:$line_number"
done

echo

# credits:
# https://github.com/philz/snippets/blob/master/pre-commit-remove-trailing-whitespace.sh
# https://github.com/imoldman/config/blob/master/pre-commit.git.sh

# Now we can commit
exit
