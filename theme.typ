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
      show raw: set text(
        size: 24pt,
        font: "DejaVu Sans Mono",
        weight: "regular",
      )
      body
    },
  ),
)
