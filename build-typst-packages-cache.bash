# shellcheck shell=bash

set -euo pipefail

# Only preview packages are supported for now
declare -r inputPackagesDir="${typstPackagesSrc:?}/packages/preview"
declare -r outputPackagesDir="${out:?}/${cacheDirPrefix:-}typst/packages/preview"

# Associative array for fast lookups
# Maps identifier (`@preview/typst:0.1.0`) to subpath (`typst/0.1.0`)
declare -Ag processedDependencies=()
declare -Ag unprocessedDependencies=()

findUnprocessedDependencies() {
  local -r searchPath="$1"
  local -a identifiers=()

  nixLog "searching for dependencies in ${searchPath@Q}"

  # Find all dependencies in the file
  mapfile -t identifiers < \
    <(rg \
      --only-matching \
      --no-filename \
      --no-line-number \
      --no-column \
      --line-regexp \
      --regexp '#import\s+"(@preview/[^":]+:[\d\.]+)".*' \
      --replace '$1' \
      "$searchPath" |
      sort -u)

  local identifier
  for identifier in "${identifiers[@]}"; do
    # If the identifier is already processed, skip it
    if [[ -n ${processedDependencies[$identifier]:-} ]]; then
      nixLog "found processed dependency ${identifier@Q}, skipping"
      continue
    # If the identifier is waiting to be processed, skip it
    elif [[ -n ${unprocessedDependencies[$identifier]:-} ]]; then
      nixLog "found queued unprocessed dependency ${identifier@Q}, skipping"
      continue
    fi

    # Otherwise, add it to the unprocessed dependencies
    nixLog "found new unprocessed dependency ${identifier@Q}, adding"
    # Use bash regex to extract the name and version
    if [[ $identifier =~ ^@preview/([^:]+):([0-9\.]+)$ ]]; then
      unprocessedDependencies["$identifier"]="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    else
      nixLog "failed to parse identifier ${identifier@Q}"
      exit 1
    fi
  done

  return 0
}

bfsProcessDependencies() {
  local -a identifiers
  local identifier
  local subpath
  local inputPath
  local outputPath

  # While there are unprocessed dependencies
  while ((${#unprocessedDependencies[@]} > 0)); do
    for identifier in "${!unprocessedDependencies[@]}"; do
      subpath="${unprocessedDependencies[$identifier]}"
      inputPath="$inputPackagesDir/$subpath"
      outputPath="$outputPackagesDir/$subpath"

      # Add symlinks to the output packages dir
      nixLog "creating symlink for dependency ${identifier@Q}"
      mkdir -p "$(dirname "$outputPath")"
      ln -s "$inputPath" "$outputPath"

      # Find the dependencies of the dependency
      nixLog "searching for dependencies of ${identifier@Q}"
      findUnprocessedDependencies "$inputPath"

      # Move it to the processed dependencies
      nixLog "processed dependency ${identifier@Q}"
      processedDependencies["$identifier"]="$subpath"
      unset 'unprocessedDependencies[$identifier]'
    done
  done

  return 0
}

# Initialize the unprocessed dependencies
findUnprocessedDependencies "${typstProjectSrc:?}"

# Process the dependencies using a breadth-first search
bfsProcessDependencies

runHook postInstall
