#!/bin/sh
# Run tests with vim and nvim if they are installed.
# Vim runs in a pseudo terminal by `script` so that window lines are set.
cd "$(dirname "$0")/.." || exit 1
status=0
out=$(mktemp)

check() {
  if [ -s "$out" ]; then cat "$out"; else echo "$1: no results"; status=1; fi
  : > "$out"
}

if command -v vim >/dev/null; then
  MATCHTAG_TEST_OUT=$out script -qec \
    'stty rows 40 cols 120; vim -N -u NONE -i NONE -S test/run.vim' \
    /dev/null >/dev/null || status=1
  check vim
fi

if command -v nvim >/dev/null; then
  MATCHTAG_TEST_OUT=$out nvim --headless -u NONE -i NONE -S test/run.vim \
    || status=1
  check nvim
fi

rm -f "$out"
exit $status
