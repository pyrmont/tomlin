(import json)
(import ../src/tomlin)
(import ../src/tomlin/json :as tomlin)


(when (nil? (os/stat "specs"))
  (print "Clone https://github.com/pyrmont/toml-specs to specs/ "
         "to run conformance tests")
  (quit))


(defn- validate [file expect actual]
  (case (type actual)
    :table
    (let [a-len (length (keys actual))
          e-len (length (keys expect))]
      (assert (= e-len a-len)
              (string file ": actual length " a-len ", expect length " e-len))
      (each [a-key a-val] (pairs actual)
        (def e-val (get expect a-key))
        (assert e-val (string file ": bad key " a-key " in " actual))
        (case (type e-val)
          :string (assert (= e-val a-val) (string file ": actual value " (describe a-val) ", expect value " (describe e-val)))
          :array (validate file e-val a-val)
          :table (validate file e-val a-val)
          (error "impossible"))))
    :array
    (let [a-len (length actual)
          e-len (length expect)]
      (assert (= e-len a-len)
              (string file ": actual length " a-len ", expect length " e-len))
      (loop [i :range [0 a-len]]
        (def a-val (get actual i))
        (def e-val (get expect i))
        (assert e-val (string file ": bad item " a-val " in " actual))
        (case (type a-val)
          :table (validate file e-val a-val)
          (error "impossible"))))))


(def valid-dir "specs/values/")


(each filename (os/dir valid-dir)
  (when (string/has-suffix? ".json" filename)
    (def json-file (string valid-dir filename))
    (def toml-file (string/replace ".json" ".toml" json-file))
    (def expect (try (-> (slurp json-file)
                         (json/decode))
                     ([err fib]
                      (propagate (string json-file ": " err) fib))))
    (def actual (try (-> (slurp toml-file)
                         (tomlin/toml->janet)
                         (tomlin/janet->json)
                         (json/decode))
                     ([err fib]
                      (propagate (string toml-file ": " err) fib))))
    (validate toml-file expect actual)))


(def error-dir "specs/errors/")


(each filename (os/dir error-dir)
  (var errored? false)
  (def toml-file (string error-dir filename))
  (try (do
         (-> (slurp toml-file)
             (tomlin/toml->janet)))
       ([err fib]
        # (debug/stacktrace fib)
        # (print toml-file ": " err)
        (set errored? true)))
  (unless errored?
    (error (string toml-file)))
  (set errored? false))
