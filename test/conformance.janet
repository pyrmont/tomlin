(import ../deps/medea/medea/decode :as medea)
(import ../lib/converter :as tomlin)
(import ../helpers/json :as helper)


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
              (string file ":\nactual length " a-len ", expect length " e-len))
      (each [a-key a-val] (pairs actual)
        (def e-val (get expect a-key))
        (assert e-val (string file ":\nbad key " a-key " in " actual))
        (case (type e-val)
          :string (assert (= e-val a-val) (string file ":\nactual value " (describe a-val) "\nexpect value " (describe e-val)))
          :array (validate file e-val a-val)
          :table (validate file e-val a-val)
          (error "impossible"))))
    :array
    (let [a-len (length actual)
          e-len (length expect)]
      (assert (= e-len a-len)
              (string file ":\nactual length " a-len ", expect length " e-len))
      (loop [i :range [0 a-len]]
        (def a-val (get actual i))
        (def e-val (get expect i))
        (assert e-val (string file ":\nbad item " a-val " in " actual))
        (case (type a-val)
          :table (validate file e-val a-val)
          (error "impossible"))))))


(def valid-dir "specs/valid")
(def valid-files (map |(string valid-dir "/" $) (os/dir valid-dir)))

(each filename valid-files
  (if (= :directory (os/stat filename :mode))
    (array/concat valid-files (map |(string filename "/" $) (os/dir filename)))
    (when (string/has-suffix? ".json" filename)
      (def json-file filename)
      (def toml-file (string/replace ".json" ".toml" json-file))
      (def expect (try (-> (slurp json-file)
                           (medea/decode))
                       ([err fib]
                        (propagate (string json-file ": " err) fib))))
      (def actual (try (-> (slurp toml-file)
                           (tomlin/toml->janet)
                           (helper/janet->json)
                           (medea/decode))
                       ([err fib]
                        (propagate (string toml-file ": " err) fib))))
      (validate toml-file expect actual))))


(def invalid-dir "specs/invalid")
(def invalid-files (map |(string invalid-dir "/" $) (os/dir invalid-dir)))


(each filename invalid-files
  (if (= :directory (os/stat filename :mode))
    (array/concat invalid-files (map |(string filename "/" $) (os/dir filename)))
    (do
      (var errored? false)
      (def toml-file (string invalid-dir filename))
      (try (do
             (-> (slurp toml-file)
                 (tomlin/toml->janet)))
           ([err fib]
            # (debug/stacktrace fib)
            # (print toml-file ": " err)
            (set errored? true)))
      (unless errored?
        (error (string toml-file)))
      (set errored? false))))
