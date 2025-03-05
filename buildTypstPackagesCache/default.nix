{ ripgrep, stdenvNoCC }:
{
  # A list of directories each containing directories of the form `<namespace>/<package>/<version>`
  packagesSources,
  # The Typst project to build
  projectSource,
}:
# Produces an output containing containing directories of the form `<namespace>/<package>/<version>`.
# As such, the outPath can be provided to TYPST_PACKAGE_CACHE_PATH and TYPST_PACKAGE_PATH.
stdenvNoCC.mkDerivation {
  __structuredAttrs = true;
  strictDeps = true;
  preferLocalBuild = true;
  allowSubstitutes = false;

  name = "typst-packages-cache";
  src = null;

  inherit packagesSources;
  inherit projectSource;

  nativeBuildInputs = [ ripgrep ];

  buildCommandPath = ./build-typst-packages-cache.bash;
}
