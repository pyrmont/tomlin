## This file is for testing purposes and is not intended to be used as part of
## the library

(varfn janet->json* :private [val])


(defn- dekeyword [kw]
  (def str (string kw))
  (case (get str 0)
    34 (string/slice str 1 -2)
    39 (string/slice str 1 -2)
    str))


(defn- escape [s]
  (def b @"")
  (var i 0)
  (while (< i (length s))
    (def c (get s i))
    (->> (cond
           (= c 0x08)
           "\\b"
           (= c 0x09)
           "\\t"
           (= c 0x0A)
           "\\n"
           (= c 0x0C)
           "\\f"
           (= c 0x0D)
           "\\r"
           (= c 0x22)
           "\\\""
           (= c 0x5C)
           "\\\\"
           (= c 0x7F)
           (string/format "\\u%04x" c)
           (< c 0x20)
           (string/format "\\u%04x" c)
           # 1-byte variant (0xxxxxxx)
           (< c 0x80)
           (string/format "%c" c)
           # 2-byte variant (110xxxxx 10xxxxxx)
           (< 0xBF c 0xE0)
           (string/format "\\u%04x"
                          (bor (blshift (band c 0x1F) 6)
                               (band (get s (++ i)) 0x3F)))
           # 3-byte variant (1110xxxx 10xxxxxx 10xxxxxx)
           (< c 0xF0)
           (string/format "\\u%04x"
                          (bor (blshift (band c 0x0F) 12)
                               (blshift (band (get s (++ i)) 0x3F) 6)
                               (band (get s (++ i)) 0x3F)))
           # 4-byte variant (11110xxx 10xxxxxx 10xxxxxx 10xxxxxx)
           (< c 0xF8)
           (string/format "\\U%08x"
                          (bor (blshift (band c 0x07) 18)
                               (blshift (band (get s (++ i)) 0x3F) 12)
                               (blshift (band (get s (++ i)) 0x3F) 6)
                               (band (get s (++ i)) 0x3F)))
           (error (string "invalid byte:" c)))
         (buffer/push b))
    (++ i))
  b)


(defn- datetime-or-table [val]
  (def ks (sort (keys val)))
  (def dt-types
    {:odt-fracs    @[:day :hour :mins :month :offset :secfracs :secs :year]
     :odt-no-fracs @[:day :hour :mins :month :offset :secs :year]
     :ldt-fracs    @[:day :hour :mins :month :secfracs :secs :year]
     :ldt-no-fracs @[:day :hour :mins :month :secs :year]
     :ld           @[:day :month :year]
     :lt-fracs     @[:hour :mins :secfracs :secs]
     :lt-no-fracs  @[:hour :mins :secs]})
  (or (case (length ks)
        8 (cond (deep= ks (dt-types :odt-fracs)) :odt)
        7 (cond (deep= ks (dt-types :odt-no-fracs)) :odt
                (deep= ks (dt-types :ldt-fracs)) :ldt)
        6 (cond (deep= ks (dt-types :ldt-no-fracs)) :ldt)
        4 (cond (deep= ks (dt-types :lt-fracs)) :lt)
        3 (cond (deep= ks (dt-types :ld)) :ld
                (deep= ks (dt-types :lt-no-fracs)) :lt))
      :table))


(defn- type-of-value [val]
  (case (type val)
    :array    :array
    :boolean  :boolean
    :core/s64 :integer
    :number   :float
    :string   :string
    :struct   :struct
    :table    (datetime-or-table val)))


(defn- array->json [val]
  (def json @"")
  (buffer/push json `{ "type": "array", "value": [ `)
  (var first? true)
  (each item val
    (if first?
      (set first? false)
      (buffer/push json ", "))
    (buffer/push json (janet->json* item)))
  (buffer/push json " ] }")
  json)


(defn- atomic->json [val type-name]
  (def json @"")
  (buffer/push json `{ "type": "`)
  (buffer/push json type-name)
  (buffer/push json `", "value": "`)
  (buffer/push json (case type-name
                      "float"  (string/format "%.16g" val) # Is this safe?
                      "string" (-> val escape)
                      (string val)))
  (buffer/push json `" }`)
  json)


(defn dt->rfc3339 [dt]
  (def buf @"")
  (when-let [year (get dt :year)
             month (get dt :month)
             day (get dt :day)]
    (buffer/push buf (string/format "%d-%02d-%02d" year month day)))
  (when-let [hour (get dt :hour)
             mins (get dt :mins)
             secs (get dt :secs)]
    (when (not (zero? (length buf)))
      (buffer/push buf "T"))
    (buffer/push buf (string/format "%02d:%02d:%02d" hour mins secs)))
  (when-let [secfracs (get dt :secfracs)]
    (buffer/push buf (string "." secfracs)))
  (when-let [offset (get dt :offset)]
    (if (= "Z" offset)
      (buffer/push buf "Z")
      (let [hour (get offset :hour)
            mins (get offset :mins)]
        (buffer/push buf (string/format "%+03d:%02d" hour mins)))))
  buf)


(defn- datetime->json [val dt-type]
  (def json @"")
  (buffer/push json `{ "type": "`)
  (buffer/push json (case dt-type
                      :odt "offset datetime"
                      :ldt "local datetime"
                      :ld  "local date"
                      :lt  "local time"))
  (buffer/push json `", "value": "`)
  (buffer/push json (dt->rfc3339 val))
  (buffer/push json `" }`)
  json)


(defn- table->json [input]
  (def json @"")
  (buffer/push json "{ ")
  (var first? true)
  (each k (sort (keys input))
    (def val (get input k))
    (if first?
      (set first? false)
      (buffer/push json ", "))
    (buffer/push json (string `"` (-> k dekeyword escape) `": `))
    (buffer/push json (janet->json* val)))
  (buffer/push json " }")
  json)


(varfn janet->json* :private [val]
  (case (type-of-value val)
    :array    (array->json val)
    :boolean  (atomic->json val "boolean")
    :integer  (atomic->json val "integer")
    :float    (atomic->json val "float")
    :ldt      (datetime->json val :ldt)
    :ld       (datetime->json val :ld)
    :lt       (datetime->json val :lt)
    :odt      (datetime->json val :odt)
    :string   (atomic->json val "string")
    :struct   (table->json val)
    :table    (table->json val)))


(defn janet->json [val]
  (string (janet->json* val)))
