{
  numRuns,
  system,
}:
let
  inherit (builtins)
    attrNames
    attrValues
    getFlake
    import
    mapAttrs
    ;

  nixTagToRev = import ./nix-tag-to-rev.nix;
  nixTagToFlake = mapAttrs (_: rev: getFlake "github:NixOS/nix/${rev}") nixTagToRev;
  nixTagToPackage = mapAttrs (_: nixFlake: nixFlake.packages.${system}.nix) nixTagToFlake;

  nixpkgsFlakeUri = "github:NixOS/nixpkgs/feb59789efc219f624b66baf47e39be6fe07a552";
  nixpkgsFlake = getFlake nixpkgsFlakeUri;
  benchNixEval = import ./bench-nixpkgs-eval.nix;

  pkgs = nixpkgsFlake.legacyPackages.${system};

  mkAggregate =
    {
      name,
      attrPath,
      filePath,
    }:
    pkgs.runCommand name
      {
        allowSubstitutes = false;
        preferLocalBuild = true;

        __structuredAttrs = true;
        strictDeps = true;

        benchNixEvalRuns = map (
          tag:
          benchNixEval {
            inherit
              nixpkgsFlakeUri
              numRuns
              pkgs
              system
              attrPath
              filePath
              ;
            nixFlakeUri = "github:NixOS/nix/${nixTagToRev.${tag}}";
          }
        ) (attrNames nixTagToFlake);

        nativeBuildInputs = [ pkgs.jq ];
      }
      ''
        for benchNixEvalRun in "''${benchNixEvalRuns[@]}"; do
          cat "$benchNixEvalRun/runs.json" >> aggregated.json
        done
        mkdir -p "$out"
        jq --sort-keys --slurp 'add' < "aggregated.json" > "$out/aggregated.json"
      '';
in
{
  # An easy way to build all requisite Nix versions
  all-nix-packages = pkgs.releaseTools.aggregate {
    name = "all-nix-packages";
    constituents = attrValues nixTagToPackage;
  };

  nixpkgs = {
    release-attrpaths-superset-names = mkAggregate {
      name = "nixpkgs-release-attrpaths-superset-names-aggregated";
      attrPath = "names";
      filePath = "pkgs/top-level/release-attrpaths-superset.nix";
    };
    unstable = mkAggregate {
      name = "nixpkgs-unstable-aggregated";
      attrPath = "unstable";
      filePath = "pkgs/top-level/release.nix";
    };
  };

  nixos = {
    iso_gnome = mkAggregate {
      name = "nixos-iso-gnome-aggregated";
      attrPath = "iso_gnome.${system}";
      filePath = "nixos/release.nix";
    };
    closures = {
      kde = mkAggregate {
        name = "nixos-closures-kde-aggregated";
        attrPath = "closures.kde.${system}";
        filePath = "nixos/release.nix";
      };
      lapp = mkAggregate {
        name = "nixos-closures-lapp-aggregated";
        attrPath = "closures.lapp.${system}";
        filePath = "nixos/release.nix";
      };
      smallContainer = mkAggregate {
        name = "nixos-closures-smallContainer-aggregated";
        attrPath = "closures.smallContainer.${system}";
        filePath = "nixos/release.nix";
      };
    };
  };
}
