#import "/globals.typ": *

#show: metropolis-theme.with(
  aspect-ratio: "4-3",
  config-info(
    title: [Evaluating the Nix Evaluator],
    subtitle: [Why Nix Performance Sometimes… Doesn't],
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
      set heading(numbering: numbly("{1}.", default: "1.1"))
      set text(size: 24pt)
      body
    },
  ),
)

#title-slide()

= Assumptions

#pause
#speaker-note[
  - Two important assumptions we need to make
]

1. Can improve
#pause
#speaker-note[
  - The first assumption is that we can improve the performance of the Nix evaluator
  - If that's not possible, then sad.
]
2. Should improve
#speaker-note[
  - The second assumption is that it is worthwhile to improve the performance of the Nix evaluator
  - If it's not worthwhile, then sad.
]

== Nix evaluation performance can be improved

- Low-hanging fruit #pause
#speaker-note[
  - Nix has grown over time
  - Many opportunities for improvement
]
- Some improvements are easy to find #pause
#speaker-note[
  - ex. Meson LTO and O3
]

== Nix evaluation performance should be improved

- Always tradeoffs to be made #pause
  - time $<->$ space #pause
  - portability $<->$ performance #pause
  - maintainability $<->$ implementation complexity #pause
- TODO: Discuss how this talk addresses concerns orthogonal to an optimizing interpeter

= Benchmarking setup

== What do we want to measure?

- TODO

== Why do we want to measure it?

- TODO

== How will we measure it?

- TODO

= Nix evaluation performance trends

- Charts foe evaluation performance over time
- Discuss axes on which evaluation can be expensive
  - Evaluator implementation
  - Nix data structures
  - Nix expressions

= Survey of data structures in the evaluator

- TODO

= Proposed improvements

- TODO
