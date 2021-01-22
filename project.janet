(declare-project
  :name "Tomlin"
  :description "A TOML parser for Janet"
  :author "Michael Camilleri"
  :license "MIT"
  :url "https://github.com/pyrmont/tomlin"
  :repo "git+https://github.com/pyrmont/tomlin"
  :dependencies ["https://github.com/janet-lang/spork"
                 "https://github.com/janet-lang/json"
                 "https://github.com/pyrmont/testament"])


(declare-source
  :source ["src/tomlin.janet"])
