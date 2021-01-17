(import ./tomlin/grammar)


(defn- insert-into-table [target name v]
  (def ks (->> (string/split "." name) (map keyword)))
  (put-in target ks v)
  v)


(defn- get-from-std-table [target name]
  (def ks (->> (string/split "." name) (map keyword)))
  (or (get-in target ks)
      (insert-into-table target name @{})))


(defn- get-from-array-table [target name]
  (def ks (->> (string/split "." name) (map keyword)))
  (var prev nil)
  (var curr target)
  (each k ks
    (when (nil? (get curr k))
      (put curr k @[]))
    (let [k-array   (get curr k)
          new-table @{}]
        (array/push k-array new-table)
        (set curr new-table)))
  curr)


(defn- build-table [elements]
  (def top @{})
  (var curr-table top)
  (var std-table? true)
  (var i 0)
  (while (def element (get elements i))
    (case element
      'array-table (set std-table? false)
      'std-table   (set std-table? true))
    (case (type element)
      :symbol  (let [table-name (get elements (++ i))
                     next-table (if std-table?
                                  (get-from-std-table top table-name)
                                  (get-from-array-table top table-name))]
                 (set curr-table next-table))
      :keyword (insert-into-table curr-table element (get elements (++ i))))
    (++ i))
  top)


(defn toml->table [input]
  (-> (peg/match grammar/toml input)
      (build-table)))
