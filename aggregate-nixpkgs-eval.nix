{
  system,
}:
let
  nixpkgsFlakeUri = "github:NixOS/nixpkgs/feb59789efc219f624b66baf47e39be6fe07a552";
  nixTagToRev = {
    # 2.3
    # Excluded because we need flakes, and 2.3 doesn't have them, excluding 2.3.18, which has a best-effort flake.
    # "2.3" = "f2908219aec34a217bd0c671162d9f343c54bc7c";
    # "2.3.1" = "dde3fa08d72461c0acecfa10b6b3fdb6b4b6367a";
    # "2.3.2" = "615d36e5cef28ddf6671f9bef6686eb2d923d172";
    # "2.3.3" = "c58bcff42aa07549110dfe420a0cae3acca55908";
    # "2.3.4" = "be66c7a6b24e3c3c6157fd37b86c7203d14acf10";
    # "2.3.5" = "fbe17c4b29b70f3bedab51a1bcad88fb9ba77db7";
    # "2.3.6" = "8971a1166e395dc55143c41afe69198265c4ac53";
    # "2.3.7" = "c9aaa6915bb2542bf89ee3886ff7a1a9a5852322";
    # "2.3.8" = "5c67d05756862e6d3a1b344945767bb35b5f44f9";
    # "2.3.9" = "6be9769b1eb70add8c4226dbcad05f9b67592ae3";
    # "2.3.10" = "d593bb7d7065be93d2da4a5e666d3dc1466f8a03";
    # "2.3.11" = "3559c5fb8ae93a1d0823cb90ff4740890711c185";
    # "2.3.12" = "6b1ece93701c055fef49e034494060fec363b797";
    # "2.3.13" = "66f1a26dfa4f55eeec9214c6598db8548637b3cc";
    # "2.3.14" = "3136bd649208532f9aa80a53eb40c14f8a163d9f";
    # "2.3.15" = "23568ee4493aca1beac0c61dd83536d0a53f3012";
    # "2.3.16" = "d54f6523201a4d5c2b43e7443b5ec7aeb3c8e376";
    # "2.3.17" = "dd6a5f0b307eafd15c9855c407c281c450d5257c";
    # "2.3.18" = "8ccd730aa1431ad132a57d1a804ff924aaea0917";

    # Commented out while working on graphs.
    # # 2.4
    # "2.4pre-rc1" = "840ace43e8d066387252af3cc95f3af4b57e264d";
    # "2.4" = "fd8f371c38bd3d06f03649bc3212a44f6f4fc6cc";

    # # 2.5
    # "2.5.0" = "678fd180c2ed2946b7dc3b72717a2fef9d793517";
    # "2.5.1" = "91bad6a9fe1367e575b2a0332992ecbe89d278de";

    # # 2.6
    # "2.6.0" = "9b44ed80dbfca7f2e435d33e41c3f92073073217";
    # "2.6.1" = "063d5f0ccafe7cecbc14a1dfc687b915d164fe49";

    # # 2.7
    # "2.7.0" = "76b5b41e7097d4e04df30e4d9ecb97a8084b9355";

    # # 2.8
    # "2.8.0" = "61fb998bba23e7b65effb9fdbf3168dc464db408";
    # "2.8.1" = "52cfe64ab387d54ff2be41d5b74c5af5a0fb67d1";

    # # 2.9
    # "2.9.0" = "a4c0327765e8b4556dc2aa04c30a102de299238c";
    # "2.9.1" = "80ea374644043c7acf937f81d33bdad78d2742e0";
    # "2.9.2" = "6bbb8e36c9997b397ace774e828fe1723ad99748";

    # # 2.10
    # "2.10.0" = "96d067a3923b1f121c143441cb669049a458e4bb";
    # "2.10.1" = "e6a45a9427cbdd7a971e50bedcb53bcaad1adfb2";
    # "2.10.2" = "2c2061911c20d65ddfabe51337de3d0e0f382105";
    # "2.10.3" = "309c2e27542818b74219d6825e322b8965c7ad69";

    # # 2.11
    # "2.11.0" = "f79ed37ccae9cc750c22e763ad44b13dcfe30013";
    # "2.11.1" = "3c7fe3b498178f256957cee022ab68c28bf6d5e3";

    # # 2.12
    # "2.12.0" = "63ce897933f0023d18de6a9ee00959dfc4e5f9b4";
    # "2.12.1" = "b096ef67e1ba480401868c2fb3f5d29d438ff07e";

    # # 2.13
    # "2.13.0" = "2b838a86b925a0b503f20f9c65adc0809140ac97";
    # "2.13.1" = "24810e2ee2fdc082aade69068b711b2ce73fd9a1";
    # "2.13.2" = "4935cf4d9b74405c753942197c9f328075793502";
    # "2.13.3" = "99e55c18fc72b57899d6cd8c70cd33ba8f8868b8";
    # "2.13.4" = "7479de7ad003f3e5770d172f4e34813a786145ba";
    # "2.13.5" = "85603517ec74ee9f3bdf90cdb1936c1727717781";
    # "2.13.6" = "4ee6f1ff8ec789a9f79cb7bf24ef49df6a92eafb";

    # # 2.14
    # "2.14.0" = "a213a5b5c2f0ddabab2f98ef88ceb685dc5d6f24";
    # "2.14.1" = "586c0ef212a60d7ec8f84b7168b46f028377ad49";

    # # 2.15
    # "2.15.0" = "ab0f8a8e35b842c83fe53c11cd856cd37171e88f";
    # "2.15.1" = "63b1244942ead27e76b73158266fb91637b98ce0";
    # "2.15.2" = "0e8ce3aa318cce3d29762e78bc82b4acf8f5238e";
    # "2.15.3" = "0feb17a1121f735bfbad8b3eb71436b7388d4ae1";

    # # 2.16
    # "2.16.0" = "4afb80d43db6a9254028abbd7818e6b942c3f927";
    # "2.16.1" = "cb5bdb4f9c6dd229a4fa7701da7aec889044a631";
    # "2.16.2" = "67857761838bd4433b5900762d761d3583711ac4";
    # "2.16.3" = "bd5985d93ddbac18bb9a9e09191f4f87d27b8848";

    # # 2.17
    # "2.17.0" = "c537a8869c3c0502ed454358c78b8029a2d832c2";
    # "2.17.1" = "c87b8cc9cbc80eeefe0cd35222f4ee6118672b0b";
    # "2.17.2" = "89c4436ebe9d9053715aeea036801e5aea5471ae";

    # # 2.18
    # "2.18.0" = "872367b841c9790fdf8726ae8fccde32fc161592";
    # "2.18.1" = "893cc9c3e89743c020697aa69922d7d993cd7816";
    # "2.18.2" = "bafe6e9416682cccf92b0e6ae7a506c41320236c";
    # "2.18.3" = "21a5199107af010a779e8f5ebaf4c352c193a97e";
    # "2.18.4" = "d84fde19dc0afa8dc7bfcc7f104d1391f4b725fc";
    # "2.18.5" = "58fc092bed50ed43c622becf28134812ba4b1dce";
    # "2.18.6" = "6eb9a6f95968539747a21c640ca52b9cc976a48c";
    # "2.18.7" = "147f53a3ad2beb0f42c7a16bef24d4183e3054bb";
    # "2.18.8" = "4d166a6f42138e4a1bf10bd5fdf132f89cfc37e0";
    # "2.18.9" = "24b271c3f73758b9a349fce7eb5a5fd23be45a1d";

    # # 2.19
    # "2.19.0" = "f8b4817ae03d7284b8a49150e8349acf9ede42d1";
    # "2.19.1" = "682a5c29ae4c62e2123eeacaee34d56c4dcfcbe6";
    # "2.19.2" = "9a2c2844a67d132ec0910e8c9101382a734e1706";
    # "2.19.3" = "8b3369437900cd0f1220ac5d68c0248f2d27abeb";
    # "2.19.4" = "3eddee0f1c2f31be0af5c515a61bffdb8c703a45";
    # "2.19.5" = "153be46e88ae5a76cb0168f7e0e1f9dfc450bc02";
    # "2.19.6" = "a317f8d07ba725c3982378ef89264cf6281676e1";
    # "2.19.7" = "faa7f9f7f1d6249b854dcb9c142898b3550830f1";

    # # 2.20
    # "2.20.0" = "de0461328c5fb7f7e272265a842cee9b0f080213";
    # "2.20.1" = "f850377a08531c97e1a4b493075d68f68e3d6f5c";
    # "2.20.2" = "59041e280284c5c12a558fbf2c58199071256a96";
    # "2.20.3" = "340714ecbf008dc89e95252b34404a5e364e7962";
    # "2.20.4" = "d61e687f7285a2a3c9efa2e8bb132e01e5c8913d";
    # "2.20.5" = "85b638cceaf269fce7f7c145aa5d34ddd2a499e1";
    # "2.20.6" = "046cab117907f5cd1098cfd1d9a7b713d22ff8c1";
    # "2.20.7" = "b60c3fa6078041eb60a01e8724caeed1d5c0bd17";
    # "2.20.8" = "2382772fd8deb69becdbe73cfc93db4cadeb5fd0";
    # "2.20.9" = "903160fb2eced6b64884f1bba27bf5f64f00b9e4";

    # # 2.21
    # "2.21.0" = "80832adcf1ce58565e35e6b5512b7295c34d3d78";
    # "2.21.1" = "fd5a907a3f306285e0ac2455a3f343cfdfd97def";
    # "2.21.2" = "5f56fdfd06a312e94414b4476b9f143d7d2945d1";
    # "2.21.3" = "3f1e023bc0bc91fdb416b5503b29ad2dd9bafdd8";
    # "2.21.4" = "529c3eaeb407c27eb5cd0ef98d3696ae6caac787";
    # "2.21.5" = "0bef542b562827373ac0f552ca8b853439f4e7e1";

    # # 2.22
    # "2.22.0" = "21165da9f255c76608166dbacdbec8a57b07a8e5";
    # "2.22.1" = "06fe4a4879b760db39e529ee4b9515df585f334a";
    # "2.22.2" = "4969af02f77a5f815411e583d19b00f3af6da50b";
    # "2.22.3" = "a68c2cc42380edd01b14440a3b02c5049c53e5e3";
    # "2.22.4" = "bb67fba379605baba817818e4a2b03bb1222fe61";

    # # 2.23
    # "2.23.0" = "19dcef29adc310295432fe52c30c75cb0a5f92b6";
    # "2.23.1" = "88b8eab8e2336f2110837ceed1a0df0733d35e97";
    # "2.23.2" = "e37b2ce90aeead5c15473b30d01b750462471ac0";
    # "2.23.3" = "fe86bf42130e4d73fce17bf74d8b9e5927239092";
    # "2.23.4" = "c366d179642e7b073c49f353d23d864d4b36e872";

    # # # 2.24
    # "2.24.0" = "bdfe2d2cfda4a221cf238fb9921e27020e352e5c";
    # "2.24.1" = "d07145022bb6b329ec88875a618561ed0711c638";
    # "2.24.2" = "3c0a51edb818ad38956500402ac7068775526010";
    # "2.24.3" = "be6bcc2b2aca76755dd6b326ab31322b3c76f4f2";
    # "2.24.4" = "d933b4d918bfd60439ebc03a687fc90181f2f076";
    # "2.24.5" = "5360adb18b9c60f03349a8d9b2ff36d265be0ded";
    # "2.24.6" = "f80dca783c9876503c3323fd3fd256c89735ce8f";
    # "2.24.7" = "7003cc4d583e0599e85edb782370bc050e9cc367";
    # "2.24.8" = "8b44aebf2f6b5e678a462a48482b142e66e882b8";
    # "2.24.9" = "04206730cbd978e199bb1a5055b74607f0387654";
    # "2.24.10" = "cfdb32c55b5cdbb096cd9ea4a65224fd1210c6df";
    # "2.24.11" = "24c4cf419dfef7154e6d87475bb16ffe66bf737d";
    # "2.24.12" = "eada2a44b4475f442b18f00c3a3f8462e96366b3";

    # 2.25
    "2.25.0" = "d769c4e1824469d2ffa7312104588cf0503de69a";
    "2.25.1" = "dfe42b7db52f6bec2a0cdcd0ce54ee2505a6aa69";
    "2.25.2" = "6d91e830c43675d8814c58dfe0ac3ce0a6164faf";
    "2.25.3" = "06340c8d5832b411ff7d20e70e9dc74e29de427a";
    "2.25.4" = "5db2e2b121758aa4cc45b2b5a539a5387c9281b1";
    "2.25.5" = "530ba561bc0c427256f284b46e68f007ae9e663e";

    # 2.26
    "2.26.0" = "717372382f75be6832c73ec5519e5d6b9aa5141b";
    "2.26.1" = "01eb3cce9a9675f4b18ed655128cfd7c71b27ef2";
    "2.26.2" = "c7b537ff6d06f76a8a349f47429563603bd25948";
  };
  nixFlakes = builtins.mapAttrs (_: rev: builtins.getFlake "github:NixOS/nix/${rev}") nixTagToRev;
  nixPackages = builtins.mapAttrs (_: nixFlake: nixFlake.packages.${system}.nix) nixFlakes;

  nixpkgsFlake = builtins.getFlake nixpkgsFlakeUri;
  benchNixEval = builtins.import ./bench-nixpkgs-eval.nix;

  inherit (nixpkgsFlake.legacyPackages.${system})
    jq
    runCommand
    http-server
    writeShellApplication
    releaseTools
    ;

  allNixPackages = releaseTools.aggregate {
    name = "nix-all";
    constituents = builtins.attrValues nixPackages;
  };

  # TODO:
  # https://vega.github.io/editor/#/examples/vega-lite/layer_line_mean_point_raw
  # NOTE: https://stackoverflow.com/questions/68229197/vega-does-not-correctly-read-timestamps-from-python-time-time
  # "transform": [
  #   {"calculate": "datetime(1000 * datum.info.nixFlake.lastModified)", "as": "time"}
  # ],
  multipleFirefox =
    runCommand "nix-eval-${system}-firefox"
      {
        allowSubstitutes = false;
        preferLocalBuild = true;

        __structuredAttrs = true;
        strictDeps = true;

        benchNixEvalRuns = builtins.map (
          tag:
          benchNixEval {
            inherit system;
            nixFlakeUri = "github:NixOS/nix/${nixTagToRev.${tag}}";
            attrPath = [ "firefox" ];
            numRuns = 10;
            nixpkgsFlakeUri = "github:NixOS/nixpkgs/feb59789efc219f624b66baf47e39be6fe07a552";
          }
        ) (builtins.attrNames nixFlakes);

        nativeBuildInputs = [ jq ];
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
  inherit allNixPackages multipleFirefox;
}
