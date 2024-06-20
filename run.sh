#!/bin/bash

# check if shuf command is available
if ! command -v shuf > /dev/null 2>&1; then
  echo "'shuf' command is not available in your terminal! Make sure you have coreutils package installed."
  exit 0
fi

# check if declare command with -A option is valid
if ! declare -A testArray > /dev/null 2>&1; then
  echo "'delcare -A' is not available in your terminal! Make sure your bash version is 4 or above."
  exit 0
fi

chmod +x wordle.sh

bash wordle.sh