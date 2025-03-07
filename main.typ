#import "imports.typ": *
#import "theme.typ": *

#show: configure-theme(metropolis-theme)

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

= Benchmarking #emoji.clock

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

== What can we easily measure?

- Data reported by `NIX_SHOW_STATS`
  - CPU/GC time, number of certain operations, etc.
- Data reported by GNU `time`
  - IO: context switches, page faults, etc.
  - Memory: page size, maximum resident set size, etc.
  - Time: real, user, and sys time

#speaker-note[
  - How will we do the measurements?
]

== `benchmarking-nix-eval`

- Allows matrixing Nix packages and configurations through flakes
- Runs `time nix eval` inside the sandbox $n$ times
- Collects the results with some additional metadata into JSON
- Data is suitable for visualization with VegaLite

#footnote(link("https://github.com/ConnorBaker/benchmarking-nix-eval"))

#focus-slide(align: horizon + left)[
  This presentation uses *VegaLite* through *WASM* as a *Typst* package.
]

= Examples #emoji.chart

// Prior to performance numbers section, mention how of the three types, only looking at two.

== Testbed setup

- Intel i9-13900K \@ 3 GHz
  - Did not change niceness/pin to a favored core
- 96 GB DDR5 RAM
  - Did not attempt flushing caches
- Four-way ZFS RAID0
  - No deduplication/compression/integrity checking (just ARC)
  - Did not change IO niceness/flush caches
- Linux 6.12.13
- NixOS unstable \@ `2ff53fe` (2025-02-13)
- `mimalloc` as the default allocator

== Software setup

- Latest minor versions of Nix (2.13-2.26)
- 20 runs of each benchmark, one at a time, with and without GC
- Median values are plotted
  - Observed little variation between runs
- Generated data is available #footnote(link("https://github.com/ConnorBaker/benchmarking-nix-eval/releases/download/v0.0.1/aggregated-nixos-desktop-20-runs-1-job-no-boost.json"))

#include "charts.typ"

== Summary

- If you need faster evaluation, set `GC_DONT_GC`
  - `nix-eval-jobs` does this #footnote(link("https://github.com/nix-community/nix-eval-jobs/blob/4b392b284877d203ae262e16af269f702df036bc/src/nix-eval-jobs.cc#L421-L422"))
- `GC_DONT_GC` is faster than no BDWGC
  - BDWGC has

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

= Future work #emoji.magnify

== Future work

- Modularizing `benchmarking-nix-eval`
- Adding more benchmarks
- Building a web dashboard to visualize the data
- Integration into CI to detect regressions
