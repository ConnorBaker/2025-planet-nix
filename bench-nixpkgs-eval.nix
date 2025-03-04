{
  attrPath,
  numRuns,
  # TODO: Flags for common stuff like GC initial heap size, disabling GC, using Nix built without GC, etc.
  system,
  nixpkgsFlakeUri,
  nixFlakeUri,
}:
let
  inherit (builtins) getFlake toString;
  nixpkgsFlake = getFlake nixpkgsFlakeUri;
  nixFlake = getFlake nixFlakeUri;

  inherit (nixFlake.packages.${system}) nix;
  inherit (nixpkgsFlake) lib;
  inherit (nixpkgsFlake.legacyPackages.${system})
    jq
    runCommand
    time
    writeTextDir
    writeText
    ;

  inherit (lib.attrsets) showAttrPath;

  nixConfDir = writeTextDir "nix.conf" ''
    allow-import-from-derivation = false
    eval-cache = false
    experimental-features = nix-command flakes
    fsync-metadata = false
    fsync-store-paths = false
    keep-build-log = false
    keep-derivations = false
    keep-env-derivations = false
    nix-path = nixpkgs=${nixpkgsFlake.outPath}
    pure-eval = true
    restrict-eval = true
    use-xdg-base-directories = true
  '';

  # TODO: No proper escaping done on the command.
  timeFormatJson = writeText "time-format.json" ''
    {
      "time": {
        "real": %e,
        "user": %U,
        "sys": %S
      },
      "memory": {
        "maxRss": %M,
        "avgRss": %t,
        "avgTotal": %K,
        "avgUnsharedData": %D,
        "avgUnsharedStack": %p,
        "avgSharedText": %X,
        "pageSize": %Z
      },
      "io": {
        "majorPageFaults": %F,
        "minorPageFaults": %R,
        "swapsOutOfMainMemory": %W,
        "voluntaryContextSwitches": %w,
        "involuntaryContextSwitches": %c,
        "fileSystemInputs": %I,
        "fileSystemOutputs": %O,
        "socketMessagesSent": %s,
        "socketMessagesReceived": %r,
        "signalsDelivered": %k
      },
      "cmd": {
        "exitStatus": %x,
        "command": "%C"
      }
    }
  '';

  numRunsString = toString numRuns;
  attrPathString = showAttrPath attrPath;
in
runCommand
  "nix-${nixFlake.shortRev}-eval-nixpkgs-${nixpkgsFlake.shortRev}-${system}-${attrPathString}-${numRunsString}-runs"
  {
    # __impure = true;
    allowSubstitutes = false;
    preferLocalBuild = true;

    __structuredAttrs = true;
    strictDeps = true;

    # The .dev output is selected by default, which isn't what we want.
    nativeBuildInputs = [
      jq
      nix.out
      time
    ];

    evalSystem = system;
    nixArgs = [
      "--print-build-logs"
      "--show-trace"
      "--offline"
      "--system"
      system
      "--eval-system"
      system
    ];
    nixEvalArgs = [
      "--offline"
      "--read-only"
      "--json"
      "--store"
      "dummy://"
      "--eval-store"
      "dummy://"
    ];
    # "NIX_CONF_DIR" is set manually and so is not included.
    nixDirs = [
      "NIX_DATA_DIR" # Overrides the location of the Nix static data directory (default prefix/share).
      "NIX_LOG_DIR" # Overrides the location of the Nix log directory (default prefix/var/log/nix).
      "NIX_STATE_DIR" # Overrides the location of the Nix state directory (default prefix/var/nix).
      "NIX_STORE_DIR" # Overrides the location of the Nix store directory (default prefix/store).
    ];
    env = {
      NIX_CONF_DIR = nixConfDir.outPath;
      NIX_SHOW_STATS = "1";
    };
  }
  # NOTE: --file implies --impure.
  # NOTE: due to --impure we can use the nix-path setting to access nixpkgs which would otherwise be forbidden in
  # restricted eval.
  # NOTE: Still need to create the dummy stores since Nix will try to realize derivations even when provided with
  # the dummy store.
  # TODO: Make a note of the Nix and Nixpkgs versions used.
  ''
    jq \
      --null-input \
      --sort-keys \
      --argjson numRuns "${numRunsString}" \
      --arg nixVersion "${nix.version}" \
      --arg attrPath "${attrPathString}" \
      --arg system "${system}" \
      --arg nixpkgsFlakeUri "${nixpkgsFlakeUri}" \
      --argjson nixpkgsFlakeLastModified ${toString nixpkgsFlake.lastModified} \
      --arg nixpkgsFlakeRev "${nixpkgsFlake.rev}" \
      --arg nixpkgsFlakeShortRev "${nixpkgsFlake.shortRev}" \
      --arg nixFlakeUri "${nixFlakeUri}" \
      --argjson nixFlakeLastModified ${toString nixFlake.lastModified} \
      --arg nixFlakeRev "${nixFlake.rev}" \
      --arg nixFlakeShortRev "${nixFlake.shortRev}" \
      '{
        $numRuns,
        $nixVersion,
        $attrPath,
        $system,
        nixpkgsFlake: {
          uri: $nixpkgsFlakeUri,
          lastModified: $nixpkgsFlakeLastModified,
          rev: $nixpkgsFlakeRev,
          shortRev: $nixpkgsFlakeShortRev
        },
        nixFlake: {
          uri: $nixFlakeUri,
          lastModified: $nixFlakeLastModified,
          rev: $nixFlakeRev,
          shortRev: $nixFlakeShortRev
        }
      }' > "info.json"

    for runNum in {1..${numRunsString}}; do
      for dir in "''${nixDirs[@]}"; do
        export "$dir"="$(mktemp -d)"
      done
      export NIX_STORE="$NIX_STORE_DIR"

      NIX_SHOW_STATS_PATH="eval.json" \
      time \
        --format="$(cat "${timeFormatJson.outPath}")" \
        --output="time.json" \
        nix eval \
          "''${nixArgs[@]}" \
          "''${nixEvalArgs[@]}" \
          --file "${nixpkgsFlake.outPath}" \
          "${attrPathString}" \
          > /dev/null

      # Join the time and eval JSON files, nesting them under their respective keys, and append the result to the
      # eval JSON file.
      jq \
        --null-input \
        --sort-keys \
        --argjson runNum "$runNum" \
        --slurpfile time "time.json" \
        --slurpfile eval "eval.json" \
        --slurpfile info "info.json" \
        '{
          $runNum,
          info: $info[0],
          time: $time[0],
          eval: $eval[0]
        }' >> runs.json

      for dir in "''${nixDirs[@]}"; do
        rm -rf "''${!dir}"
      done
    done

    mkdir -p "$out"
    jq --sort-keys --slurp < "runs.json" > "$out/runs.json"
  ''
