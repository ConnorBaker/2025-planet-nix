#import "imports.typ": nulite, utils
#import "theme.typ": custom-colors

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

#let mk-vegalite-spec(spec: dictionary) = utils.merge-dicts(
  spec,
  (config: vegalite-config),
)

#let vegalite(spec: dictionary) = nulite.render(
  width: 100%,
  height: 100%,
  mk-vegalite-spec(spec: spec),
)

// NOTE: Generally faster to do transformations in typst than in Vega-Lite.
#let all-data = (
  json("aggregated.json").map(
    // Restricting to only data we need
    datum => (
      cpuTime: datum.eval.cpuTime,
      maxRssBytes: datum.time.memory.maxRss * 1024,
      attrPathString: datum.info.attrPath.join("."),
      tag: datum.info.nixBenchConfig.tag,
      runType: if not datum.info.nixBenchConfig.useBDWGC {
        "noBDWGC"
      } else if datum.info.nixBenchConfig.dontGC {
        "dontGC"
      } else {
        "GC"
      },
    ),
  )
)

#let datasets = (
  "firefox-unwrapped": all-data.filter(datum => (
    datum.attrPathString == "firefox-unwrapped"
  )),
  "release-attrpaths-superset.names": all-data.filter(datum => (
    datum.attrPathString == "names"
  )),
  "iso_gnome.x86_64-linux": all-data.filter(datum => (
    datum.attrPathString == "iso_gnome.x86_64-linux"
  )),
  "closures.kde.x86_64-linux": all-data.filter(datum => (
    datum.attrPathString == "closures.kde.x86_64-linux"
  )),
  "closures.lapp.x86_64-linux": all-data.filter(datum => (
    datum.attrPathString == "closures.lapp.x86_64-linux"
  )),
  "closures.smallContainer.x86_64-linux": all-data.filter(datum => (
    datum.attrPathString == "closures.smallContainer.x86_64-linux"
  )),
)

#for attrPathString in (
  "firefox-unwrapped",
  "release-attrpaths-superset.names",
  "closures.smallContainer.x86_64-linux",
  "closures.lapp.x86_64-linux",
  "closures.kde.x86_64-linux",
  "iso_gnome.x86_64-linux",
) {
  heading(attrPathString + " eval time", depth: 2)
  vegalite(
    spec: (
      data: (values: datasets.at(attrPathString)),
      mark: "circle",
      encoding: (
        x: (
          title: "Tag",
          field: "tag",
          type: "ordinal",
        ),
        color: (
          title: "Run type",
          field: "runType",
          type: "nominal",
        ),
        y: (
          title: "Eval Time (s)",
          field: "cpuTime",
          aggregate: "median",
          type: "quantitative",
        ),
        size: (value: 150),
      ),
    ),
  )

  heading(attrPathString + " eval space", depth: 2)
  vegalite(
    spec: (
      data: (values: datasets.at(attrPathString)),
      mark: "circle",
      encoding: (
        x: (
          title: "Tag",
          field: "tag",
          type: "ordinal",
        ),
        color: (
          title: "Run type",
          field: "runType",
          type: "nominal",
        ),
        y: (
          title: "Max RSS (B)",
          field: "maxRssBytes",
          axis: (format: "s"),
          aggregate: "median",
          type: "quantitative",
        ),
        size: (value: 150),
      ),
    ),
  )
}
