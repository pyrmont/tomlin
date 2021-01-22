(import ./tomlin/grammar)


(defn- insert-into-table [target ks v]
  (var t target)
  (var i 0)
  (while (< i (dec (length ks)))
    (def k (get ks i))
    (def next-t (get t k))
    (case (type next-t)
      :table
      (set t next-t)
      :nil
      (let [next-t @{}]
        (put t k next-t)
        (set t next-t))
      (error "existing value cannot be redefined as table"))
    (++ i))
  (def k (get ks i))
  (if (nil? (get t k))
    (put t k v)
    (error "existing value cannot be redefined")))


(defn- get-from-table [target ks std-table?]
  (var t target)
  (var i 0)
  (while (< i (dec (length ks)))
    (def k (get ks i))
    (def v (get t k))
    (case (type v)
      :nil
      (do
        (def next-t @{})
        (put t k (if std-table? next-t @[next-t]))
        (set t next-t))
      :array
      (set t (array/peek v))
      :table
      (set t v))
    (++ i))
  (def k (get ks i))
  (def v (get t k))
  (def final-t @{})
  (case (type v)
    :nil
    (put t k (if std-table? final-t @[final-t]))
    :array
    (cond
      std-table?
      (error "array table cannot be changed to standard table")
      (zero? (length v))
      (error "table cannot be appended to static array")
      (array/push v final-t))
    :table
    (cond
      (not std-table?)
      (error "tables must have unique key")
      (not (table? (get v (next v))))
      (error "headings can only refer to super-tables"))
    (error "existing values cannot be redefined in headings"))
  final-t)


(defn- build-table [elements]
  (def top @{})
  (var curr-table top)
  (var std-table? true)
  (var i 0)
  (while (def element (get elements i))
    (case element
      'array-table (set std-table? false)
      'std-table   (set std-table? true))
    (if (= :symbol (type element))
      (let [table-keys (get elements (++ i))
            next-table (get-from-table top table-keys std-table?)]
        (set curr-table next-table))
      (insert-into-table curr-table element (get elements (++ i))))
    (++ i))
  top)


(defn toml->janet [input]
  (def elements (peg/match grammar/toml input))
  (if (nil? elements)
    (error "input is not valid TOML")
    (build-table elements)))
