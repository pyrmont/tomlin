# Tomlin

[![Build Status][icon]][status]

[icon]: https://github.com/pyrmont/tomlin/workflows/build/badge.svg
[status]: https://github.com/pyrmont/tomlin/actions?query=workflow%3Abuild

Tomlin is a [TOML][] parser for Janet. It aims to parse only valid TOML.
It currently supports [TOML v1.0.0][spec].

[TOML]: https://toml.io
[spec]: https://toml.io/en/v1.0.0

## Installation

Add the dependency to your `project.janet` file:

```clojure
(declare-project
  :dependencies ["https://github.com/pyrmont/tomlin"])
```

## Usage

Tomlin can be used like this:


```clojure
(import tomlin)

(-> (slurp "input.toml")
    (tomlin/toml->janet)
```

## API

Documentation for Tomlin's API is in [api.md][api].

[api]: https://github.com/pyrmont/tomlin/blob/master/api.md

## Testing

Tomlin passes a suite of tests in the [toml-specs][] repository. If you clone
this repository to a directory called `specs/`, they will run as part of the
`jpm test` process.

[toml-specs]: https://github.com/pyrmont/toml-specs

## Bugs

Found a bug? I'd love to know about it. The best way is to report your bug in
the [Issues][] section on GitHub.

[Issues]: https://github.com/pyrmont/tomlin/issues

## Licence

Tomlin is licensed under the MIT Licence. See [LICENSE][] for more details.

[LICENSE]: https://github.com/pyrmont/tomlin/blob/master/LICENSE
