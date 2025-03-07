#import "imports.typ": *
#import themes.metropolis: *

#let custom-colors = config-colors(
  primary: rgb("#3BB1D5"),
  primary-light: rgb("#3BB1D5"),
  secondary: rgb("#2C3133"),
  neutral-lightest: rgb("#fafafa"),
  neutral-dark: rgb("#2C3133"),
  neutral-darkest: rgb("#2C3133"),
)

#let configure-theme = theme => theme.with(
  aspect-ratio: "4-3",
  config-info(
    title: text(weight: "bold", size: 32pt)[Evaluating the Nix Evaluator],
    subtitle: text(weight: "semibold")[Why Nix Performance Sometimes… Doesn't],
    author: [Connor Baker],
    date: datetime.today(),
    institution: [Planet Nix],
    logo: emoji.rainbow,
  ),
  config-page(
    paper: "presentation-4-3",
    header-ascent: 30%,
    footer-descent: 30%,
    margin: (top: 3em, bottom: 1.5em, x: 2em),
  ),
  header-right: [],
  footer: [],
  footer-progress: false,
  config-colors(
    primary: rgb("#3BB1D5"),
    primary-light: rgb("#3BB1D5"),
    secondary: rgb("#2C3133"),
    neutral-lightest: rgb("#fafafa"),
    neutral-dark: rgb("#2C3133"),
    neutral-darkest: rgb("#2C3133"),
  ),
  config-methods(
    init: (self: none, body) => {
      set text(size: 24pt, font: "Nacelle")
      body
    },
  ),
)

#let vegalite-config = (
  background: custom-colors.colors.neutral-lightest.to-hex(),
  font: "Nacelle",
  axis: (
    labelFont: "Nacelle",
    labelFontSize: 18,
    labelFontWeight: "medium",
    titleFont: "Nacelle",
    titleFontSize: 24,
    titleFontWeight: "bold",
  ),
  legend: (
    labelFont: "Nacelle",
    labelFontSize: 18,
    labelFontWeight: "medium",
    titleFont: "Nacelle",
    titleFontSize: 24,
    titleFontWeight: "bold",
  ),
)

// NOTE: Generally faster to do transformations in typst than in Vega-Lite.
#let all-data = (
  json("aggregated.json")
    .filter(
      // Restricting to either GC or dontGC
      datum => datum.info.nixBenchConfig.useBDWGC,
    )
    .map(
      // Restricting to only data we need
      datum => (
        eval: (
          cpuTime: datum.eval.cpuTime,
          gc: datum.eval.gc,
        ),
        info: (
          attrPathString: datum.info.attrPath.join("."),
          nixBenchConfig: (tag: datum.info.nixBenchConfig.tag),
          runType: if datum.info.nixBenchConfig.dontGC { "dontGC" } else {
            "GC"
          },
        ),
      ),
    )
)

#let datasets = (
  "firefox-unwrapped": all-data.filter(datum => (
    datum.info.attrPathString == "firefox-unwrapped"
  )),
  "release-attrpaths-superset.names": all-data.filter(datum => (
    datum.info.attrPathString == "names"
  )),
  "iso_gnome.x86_64-linux": all-data.filter(datum => (
    datum.info.attrPathString == "iso_gnome.x86_64-linux"
  )),
  "closures.kde.x86_64-linux": all-data.filter(datum => (
    datum.info.attrPathString == "closures.kde.x86_64-linux"
  )),
  "closures.lapp.x86_64-linux": all-data.filter(datum => (
    datum.info.attrPathString == "closures.lapp.x86_64-linux"
  )),
  "closures.smallContainer.x86_64-linux": all-data.filter(datum => (
    datum.info.attrPathString == "closures.smallContainer.x86_64-linux"
  )),
)

#let mk-vegalite-spec(spec: dictionary) = utils.merge-dicts(
  spec,
  (config: vegalite-config),
)

#let vegalite(spec: dictionary) = nulite.render(
  width: 100%,
  height: 100%,
  mk-vegalite-spec(spec: spec),
)
