#import "imports.typ": *
#import "utils.typ": *

#show: configure-theme(metropolis-theme)

// TODO:
// For benchmarking repo:
// - use nixos modules to build configurations to enable docs and type checking
// - the name of the

// NOTE: real/user/sys times are largely the same, not worth looking at

#title-slide()
#speaker-note[
  Nix evaluation performance is a known, long-standing issue to the community.
  This talk will cover a benchmarking setup, concessions to that setup made to retain the author's sanity, and ways to improve evaluation performance and their trade-offs.
]

== Topics covered

- Benchmarking setup
- Nix evaluation performance over time
- Suggested areas for improvement

= Assumptions #emoji.bookmark

#speaker-note[
  - Two important assumptions we need to make
]

== Nix evaluation performance

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
      - TODO: Transition to need for benchmarking -- maybe something about needing to be able to measure improvements
    ]
]

= Benchmarking setup #emoji.clock

#focus-slide(align: horizon + left)[
  Benchmarking is *difficult*.
  #speaker-note[
    - Truly an exercise fraught with peril
    - Modern consumer processors throttle hard, so need to disable boosting
    - Need to change governor to performance to avoid latency in scaling up
    - Need to run on a quiet system to minimize context switching
    - TODO: Discuss benchmark setup, caveats like caching, boosting, thermal throttling, etc
    - TODO: Discuss limitations of setup, like using the flake's toolchain and copy of Nixpkgs
  ]
]

== What do we want to measure?

- Space
- Time

== Why do we want to measure it?

- TODO

== How will we measure it?

- TODO

= Examples #emoji.chart

// Prior to performance numbers section, mention how of the three types, only looking at two.

== Setup

- Intel i9-13900K (locked to 3 GHz) with 96 GB DDR5
- Four-way ZFS RAID0 with integrity protections disabled
- Each benchmark uses 20 runs
- Median values are plotted

#include "eval-charts.typ"

== Nix evaluation performance trends

- Charts for evaluation performance over time
- Discuss axes on which evaluation can be expensive
  - Evaluator implementation
  - Nix data structures
  - Nix expressions

== What's with all the garbage?

- TODO: benchmarks without GC running and without Boehm entirely
- Transition to looking at the actual implementations

= Evaluator structures #emoji.helix

#speaker-note[
  TODO: Where's the narrative?
  Should discuss data structures like strings, lists, and attribute sets, and the way people interact with them.
  From there, create a small set of high-performance, composable builtins and build on that.
]

== Value

- Padding, etc.

== List

- Special-cased for lists of size 0, 1, and 2, which can fit in a Value
- Implemented as a C-style array, so great data locality

== Attribute set

- TODO: has it changed? I remember there being two arrays (one for names, one for values), but now it seems to be a vector of tuples.

= Improvements #emoji.crystal

#focus-slide(align: horizon + left)[
  Suggested improvements should be *orthogonal* to those an *optimizing* or *parallel interpreter* would provide.
  #speaker-note[
    - The improvements discussed in this talk are orthogonal to those an optimizing interpreter provides
    - An optimizing interpreter is a different approach to the problem of improving evaluation performance
    - It is not the focus of this talk, but it is worth mentioning
  ]
]

== Persistent data structures

- TODO
- I mean, functional programming language with immutable values so why not benefit from sharing?
- Describe Immer library

== Shrinking structures

- TODO: Link to branch I have with these changes
