#import "utils.typ": vegalite, datasets

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
          field: "info.nixBenchConfig.tag",
          type: "ordinal",
        ),
        color: (
          title: "Run type",
          field: "info.runType",
          type: "nominal",
        ),
        y: (
          title: "Eval Time (s)",
          field: "eval.cpuTime",
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
          field: "info.nixBenchConfig.tag",
          type: "ordinal",
        ),
        color: (
          title: "Run type",
          field: "info.runType",
          type: "nominal",
        ),
        y: (
          title: "Heap Size (bytes)",
          field: "eval.gc.heapSize",
          axis: (format: "s"),
          aggregate: "median",
          type: "quantitative",
        ),
        size: (value: 150),
      ),
    ),
  )
}
