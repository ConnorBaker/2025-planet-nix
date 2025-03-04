#import "/imports.typ": *
#import themes.metropolis: *

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
      set text(size: 24pt)
      body
    },
  ),
)

#title-slide()
#speaker-note[
  Nix evaluation performance is a known, long-standing issue to the community.
  This talk will cover a benchmarking setup, concessions to that setup made to retain the author's sanity, and ways to improve evaluation performance and their trade-offs.
]

= Assumptions #emoji.bookmark

#speaker-note[
  - Two important assumptions we need to make
]

== Nix evaluation performance...

#slide[
  #pause
  1. Can improve? #pause
    #speaker-note[
      - First, we're assuming we can improve the performance of the Nix evaluator
      - This assumption is about possibility: does there exist some way to improve performance?
    ]
    - Historically, yes!
    #speaker-note[
      - Historically, this has been the case
      - Improvements from string interning with a symbol table, special-cased arrays of sizes 0, 1, and 2, and more
      - Even improvements to the packaging of Nix itself: after the switch to Meson, building with optimization level three and enabling LTO
      - TODO(@ConnorBaker): LINK FOR THE ABOVE PR SO WE CAN QUOTE PERFORMANCE DIFFERENCE
      - It's a codebase which has grown organically over time, written in a language which has also grown over time (jab at C++)
    ]
][
  #pause
  2. Should improve? #pause
    #speaker-note[
      - The second assumption is that it is worthwhile to improve the performance of the Nix evaluator
      - This assumption is about practicality: for some impelementation change, is it worthwhile to make that change?
    ]
    - It depends!
    #speaker-note[
      - As with anything, it depends
      - There are always tradeoffs to be made
      - For example:
        - favoring algorithms efficient in terms of time time but not space
        - restricting baseline functionality to acheive greater portability
        - selecting complex implementations for performance over maintainability
      - The question of whether we *should* make an improvement is going to depend on the nature of the improvement
    ]
]

#focus-slide[
  Discussed improvements are *orthogonal* to those an *optimizing interpreter* provides.
  #speaker-note[
    - The improvements discussed in this talk are orthogonal to those an optimizing interpreter provides
    - An optimizing interpreter is a different approach to the problem of improving evaluation performance
    - It is not the focus of this talk, but it is worth mentioning
  ]
]

= Benchmarking setup #emoji.clock

== What do we want to measure?

- Space #emoji.sparkles
- Time #emoji.hourglass

== Why do we want to measure it?

- TODO

== How will we measure it?

- TODO

= Data visualization #emoji.chart

// Briefly, the setup.
// What do we see?

== Nix evaluation performance trends

- Charts for evaluation performance over time
- Discuss axes on which evaluation can be expensive
  - Evaluator implementation
  - Nix data structures
  - Nix expressions

== What's with all the garbage?

- TODO: benchmarks without GC running and without Boehm entirely
- Transition to looking at the actual implementations

= Abridged data structures of the evaluator #emoji.helix

#speaker-note[
  TODO: Where's the narrative?
  Should discuss data structures like strings, lists, and attribute sets, and the way people interact with them.
  From there, create a small set of high-performance, composable builtins and build on that.
]

== Value

- Padding, etc.

== List

- Special-cased for lists of size 0, 1, and 2, which can fit in a Value

== Attribute set

- TODO: has it changed? I remember there being two arrays (one for names, one for values), but now it seems to be a vector of tuples.

= Possible improvements

== Persistent data structures

- TODO
- I mean, functional programming language with immutable values so why not benefit from sharing?
- Describe Immer library

== Shrinking `Value`

- TODO: Link to branch I have with these changes
