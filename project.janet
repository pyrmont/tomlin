(declare-project
  :name "Tomlin"
  :description "A TOML parser for Janet"
  :author "Michael Camilleri"
  :license "MIT"
  :url "https://github.com/pyrmont/tomlin"
  :repo "git+https://github.com/pyrmont/tomlin"
  :dependencies []
  :dev-dependencies ["https://github.com/pyrmont/medea"
                     "https://github.com/pyrmont/testament"])

# Library

(declare-source
  :source ["src/tomlin.janet"
           "src/tomlin"])

# Development

(task "dev-deps" []
  (if-let [deps ((dyn :project) :dependencies)]
    (each dep deps
      (bundle-install dep))
    (do
      (print "no dependencies found")
      (flush)))
  (if-let [deps ((dyn :project) :dev-dependencies)]
    (each dep deps
      (bundle-install dep))
    (do
      (print "no dev-dependencies found")
      (flush))))
