# shellcheck shell=bash

set -euo pipefail

# Associative array for fast lookups
# Maps subpath (`preview/typst:0.1.0`) to source (typst packages' @preview namespace)
declare -Ag processedDependencies=()
# Maps subpath (`preview/typst:0.1.0`) to search path from which it was found
declare -Ag unprocessedDependencies=()

findUnprocessedDependencies() {
  local -r searchPath="$1"
  local -a subpaths=()
  local subpath

  nixInfoLog "searching for dependencies in ${searchPath@Q}"

  # Find all dependencies in the file
  mapfile -t subpaths < \
    <(rg \
      --only-matching \
      --no-filename \
      --no-line-number \
      --no-column \
      --line-regexp \
      --regexp '#import\s+"@([^"/]+)/([^":]+):([\d\.]+)".*' \
      --replace '$1/$2/$3' \
      --follow \
      --type-add 'typst:*.typ' \
      --type typst \
      "$searchPath" |
      sort -u)

  for subpath in "${subpaths[@]}"; do
    if [[ -n ${processedDependencies[$subpath]:-} ]]; then
      nixInfoLog "found processed dependency ${subpath@Q}, skipping"
    elif [[ -n ${unprocessedDependencies[$subpath]:-} ]]; then
      nixInfoLog "found queued unprocessed dependency ${subpath@Q}, skipping"
    else
      nixInfoLog "found new unprocessed dependency ${subpath@Q}, adding"
      unprocessedDependencies["$subpath"]="$searchPath"
    fi
  done

  return 0
}

bfsProcessDependencies() {
  local -a subpaths=()
  local subpath
  local outputPath
  local packagesSource
  local inputPath

  # shellcheck disable=SC2154
  nixLog "configured to search for dependencies in the following packages sources:" \
    "${packagesSources[@]}"

  # Initialize the unprocessed dependencies
  findUnprocessedDependencies "${projectSource:?}"

  # While there are unprocessed dependencies
  while ((${#unprocessedDependencies[@]} > 0)); do
    # Iterate through them
    for subpath in "${!unprocessedDependencies[@]}"; do
      outputPath="${out:?}/$subpath"
      # Search through the available package sources for the dependency
      # shellcheck disable=SC2154
      for packagesSource in "${packagesSources[@]}"; do
        inputPath="$packagesSource/$subpath"

        # If the dependency is not found, skip it
        if [[ ! -d $inputPath ]]; then
          nixInfoLog "dependency ${subpath@Q} not found in ${packagesSource@Q}"
          continue
        fi
        nixInfoLog "dependency ${subpath@Q} found in ${packagesSource@Q}"

        # NOTE: Because we check in findUnprocessedDependencies if the dependency has already been processed, or is
        # waiting to be processed, we can assume that it is not a duplicate.

        # Add symlinks to the output packages dir -- symlinks the version directory
        # to the output packages dir.
        nixLog "creating symlink for dependency ${subpath@Q}"
        mkdir -p "$(dirname "$outputPath")"
        ln -s "$inputPath" "$outputPath"

        # Move it to the processed dependencies
        nixInfoLog "processed dependency ${subpath@Q}"
        processedDependencies["$subpath"]="$packagesSource"
        unset 'unprocessedDependencies[$subpath]'

        # Find the dependencies of the dependency
        nixInfoLog "searching for dependencies of ${subpath@Q}"
        findUnprocessedDependencies "$inputPath"
      done

      # If the outputPath does not exist, it means the dependency was not found
      if [[ ! -d $outputPath ]]; then
        nixErrorLog "dependency ${subpath@Q} not found in any packages source:" \
          "this may be a non-issue due to the dependency search algorithm" \
          "including dependencies for manuals, tests, etc."
        processedDependencies["$subpath"]="UNRESOLVED"
        unset 'unprocessedDependencies[$subpath]'
      fi
    done
  done

  return 0
}

# Process the dependencies using a breadth-first search
bfsProcessDependencies

runHook postInstall
