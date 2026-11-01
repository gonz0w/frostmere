#!/bin/zsh
set -eu
cd "${0:A:h}"
if [[ -x ".tools/Godot.app/Contents/MacOS/Godot" ]]; then
  exec .tools/Godot.app/Contents/MacOS/Godot --path "$PWD" -- --seal-preview
elif [[ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]]; then
  exec /Applications/Godot.app/Contents/MacOS/Godot --path "$PWD" -- --seal-preview
elif command -v godot >/dev/null 2>&1; then
  exec godot --path "$PWD" -- --seal-preview
else
  print "Install Godot 4.7.2 or newer from https://godotengine.org/download/macos/ and open project.godot."
  read "?Press Return to close."
fi
