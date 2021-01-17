(def- escaped-whitespace
  (peg/compile
    ~{:main (% (* (? :nl) (any (+ :escaped-ws (<- 1)))))
      :ws (set "\t ")
      :nl (+ "\n" "\r\n")
      :escaped-ws (* "\\" :nl (any (+ :nl :ws)))}))


(def- leading-whitespace
  (peg/compile
    ~{:main (% (* (? :nl) (any (<- 1))))
      :nl (+ "\n" "\r\n")}))


(defn- remove-whitespace [delim input]
  (case delim
    `"""` (first (peg/match escaped-whitespace input))
    `'''` (first (peg/match leading-whitespace input))))


(defn- unescape-string [input]
  (defn unescape [s]
    (def c (scan-number (string "0x" s)))
    (cond
      # 1 byte variant (0xxxxxxx)
      (< c 0x80)
      (string/format "%c" c)
      # 2 byte variant (110xxxxx 10xxxxxx)
      (< c 0x800)
      (string/format "%c%c"
                     (bor 0xC0 (brshift c 6))
                     (bor 0x80 (band 0x3F c)))
      # 3 byte variant (1110xxxx 10xxxxxx 10xxxxxx)
      (< c 0x10000)
      (string/format "%c%c%c"
                     (bor 0xE0 (brshift c 12))
                     (bor 0x80 (band 0x3F (brshift c 6)))
                     (bor 0x80 (band 0x3F c)))
      # 4 byte variant (11110xxx 10xxxxxx 10xxxxxx 10xxxxxx)
      (< c 0x110000)
      (string/format "%c%c%c%c"
                     (bor 0xF0 (brshift c 18))
                     (bor 0x80 (band 0x3F (brshift c 12)))
                     (bor 0x80 (band 0x3F (brshift c 6)))
                     (bor 0x80 (band 0x3F c)))
      (error (string "Invalid Unicode point: " c))))
  (def replacer
    (peg/compile
      ~{:main (% (any (+ :escaped-char :char)))
        :escaped-char (+ (* "\\u" (/ (<- 4) ,unescape))
                         (* "\\U" (/ (<- 8) ,unescape))
                         (/ (<- "\\\"") "\"")
                         (/ (<- "\\\\") "\\")
                         (/ (<- "\\b")  "\x08")
                         (/ (<- "\\f")  "\f")
                         (/ (<- "\\n")  "\n")
                         (/ (<- "\\r")  "\r")
                         (/ (<- "\\t")  "\t"))
        :char (<- 1)}))
  (first (peg/match replacer input)))


(defn- to-string [delim input]
  (case delim
    `"`   (->> (string/slice input 1 -2)
               (unescape-string))
    `'`   (string/slice input 1 -2)
    `"""` (->> (string/slice input 3 -4)
               (remove-whitespace delim)
               (unescape-string))
    `'''` (->> (string/slice input 3 -4)
               (remove-whitespace delim))
    input))


(defn- to-boolean [input]
  (if (= "false" (string/ascii-lower input))
    false
    true))


(defn- to-array [input]
  input)


(defn- to-table [input]
  (apply table input))


(defn- to-datetime [input]
  (defn offset-dir [dir time]
    (case dir
      "+" time
      "-" (put time :hour (* -1 (get time :hour)))))
  (def extract
    (peg/compile
      ~{:main (/ (* (? :date) (? :time-delim) (? :time) (? :offset)) ,table)

        :date  (* :year "-" :month "-" :day)
        :year  (* (constant :year) (/ (<- 4) ,scan-number))
        :month (* (constant :month) (/ (<- 2) ,scan-number))
        :day   (* (constant :day) (/ (<- 2) ,scan-number))

        :time-delim (set "Tt ")

        :time  (* :hour ":" :mins (? (* ":" :secs (? (* "." :fracs)))))
        :hour  (* (constant :hour) (/ (<- 2) ,scan-number))
        :mins  (* (constant :mins) (/ (<- 2) ,scan-number))
        :secs  (* (constant :secs) (/ (<- 2) ,scan-number))
        :fracs (* (constant :secfracs) (/ (<- :d+) ,scan-number))

        :offset (* (constant :offset) (+ :zulu :num-offset))
        :zulu (/ (<- (set "Zz")) ,string/ascii-upper)
        :num-offset (cmt (* (<- (set "-+")) (/ :time ,table)) ,offset-dir)}))
  (first (peg/match extract input)))


(defn- to-number [input]
  (case (string/ascii-lower input)
    "-inf" math/-inf
    "+inf" math/inf
    "inf"  math/inf
    "-nan" math/nan
    "+nan" math/nan
    "nan"  math/nan
    (if-let [number (scan-number input)]
      number
      (case (string/slice input 0 2)
        "0o" (scan-number (string "8r" (string/slice input 2)))
        "0b" (scan-number (string "2r" (string/slice input 2)))))))


(defn- to-key [input]
  (-> (get input 0)
      (to-string input)
      keyword))


(def- toml-grammar
  # Reference: https://github.com/toml-lang/toml/blob/1.0.0/toml.abnf
  ~{:main (* :expr (any (* :nl :expr)) -1)
    :expr (+ :keyval-expr :table-expr :cmnt-expr)

    :cmnt-expr   (* :ws (? :comment))
    :keyval-expr (* :ws :keyval :ws (? :comment))
    :table-expr  (* :ws :table :ws (? :comment))

    # Whitespace

    :ws (any :ws-char)
    :ws-char (set " \t")

    :nl (+ "\n" "\r\n")

    # Hexadecimal Fix

    :h (range "09" "AF" "af")

    # UTF-8 Codepoints

    :cb (range "\x80\xBF")

    :bmp-chars (+ :bmp-2 :bmp-3)
    :bmp-2     (* (range "\xC2\xDF") :cb)
    :bmp-3     (+ (* "\xE0" (range "\xA0\xBF") :cb)
                  (* (range "\xE1\xEC") :cb :cb)
                  (* "\xED" (range "\x80\x9F") :cb))

    :smp-chars (+ :smp-3 :smp-4)
    :smp-3     (* (range "\xEE\xEF") :cb :cb)
    :smp-4     (+ (* "\xF0" (range "\x90\xBF") :cb :cb)
                  (* (range "\xF1\xF3") :cb :cb :cb)
                  (* "\xF4" (range "\x80\x8F") :cb :cb))

    # Valid Characters

    :non-ascii (+ :bmp-chars :smp-chars)
    :non-eol   (+ "\t" (range "\x20\x7F") :non-ascii)

    # Comments

    :comment (* "#" (any :non-eol))

    # Key-Value Pairs

    :keyval (* :key :keyval-sep :val)

    :key (/ (<- (+ :dotted-key :simple-key)) ,to-key)
    :simple-key (+ :quoted-key :unquoted-key)

    :unquoted-key (some (+ :a :d "-" "_"))
    :quoted-key (+ :basic-string :literal-string)

    :dotted-key (* :simple-key (some (* :dot-sep :simple-key)))
    :dot-sep    (* :ws "." :ws)

    :keyval-sep (* :ws "=" :ws)

    :val (+ (/ (<- :string)          ,to-string)
            (/ (<- :boolean)         ,to-boolean)
            (/ (group :array)        ,to-array)
            (/ (group :inline-table) ,to-table)
            (/ (<- :date-time)       ,to-datetime)
            (/ (<- :float)           ,to-number)
            (/ (<- :integer)         ,to-number))

    # String

    :string (+ (* :ml-basic-string (constant `"""`))
               (* :basic-string (constant `"`))
               (* :ml-literal-string (constant `'''`))
               (* :literal-string (constant `'`)))

    :basic-string (* `"` (any :basic-char) `"`)

    :basic-char (+ :basic-unescaped :escaped)
    :basic-unescaped (+ :ws-char "\x21" (range "\x23\x5B") (range "\x5D\x7E")
                        :non-ascii)
    :escaped (* :escape :escape-seq-char)

    :escape "\\"
    :escape-seq-char (+ `"` "\\" "b" "f" "n" "r" "t"
                        (* "u" (4 :h))
                        (* "U" (8 :h)))

    # Multiline Basic String

    :ml-basic-string (* `"""` (? :nl) :mlb-body `"""`)

    :mlb-body (* (any :mlb-content)
                 (any (* :mlb-quotes (some :mlb-content)))
                 (? :mlb-quotes))
    :mlb-content (+ :mlb-char :nl :mlb-escaped-nl)
    :mlb-char (+ :mlb-unescaped :escaped)
    :mlb-quotes (+ (* (2 `"`) (> 0 (+ (! `"`) `"""`)))
                   (* (1 `"`) (> 0 (+ (! `"`) `"""`))))
    :mlb-unescaped :basic-unescaped
    :mlb-escaped-nl (* :escape :ws :nl (any (+ :ws-char :nl)))

    # Literal String

    :literal-string (* `'` (any :literal-char) `'`)
    :literal-char (+ "\x09" (range "\x20\x26") (range "\x28\x7E") :non-ascii)

    # Multline Literal String

    :ml-literal-string (* `'''` (? :nl) :mll-body `'''`)

    :mll-body (* (any :mll-content)
                 (any (* :mll-quotes (some :mll-content)))
                 (? :mll-quotes))
    :mll-content (+ :mll-char :nl)
    :mll-char :literal-char
    :mll-quotes (+ (* (2 `'`) (> 0 (+ (! `'`) `'''`)))
                   (* (1 `'`) (> 0 (+ (! `'`) `'''`))))

    # Integer

    :integer (+ :hex-int :oct-int :bin-int :dec-int)

    :digit1-9 (range "19")
    :digit0-7 (range "07")
    :digit0-1 (range "01")

    :hex-prefix "0x"
    :oct-prefix "0o"
    :bin-prefix "0b"

    :dec-int (* (? (set "-+")) (+ (* :digit1-9 (some (+ :d (* "_" :d))))
                                  :d))
    :hex-int (* :hex-prefix :h (any (+ :h (* "_" :h))))
    :oct-int (* :oct-prefix :digit0-7 (any (+ :digit0-7 (* "_" :digit0-7))))
    :bin-int (* :bin-prefix :digit0-1 (any (+ :digit0-1 (* "_" :digit0-1))))

    # Float

    :float (+ (* :float-int-part (+ :exp (* :frac (? :exp))))
              :special-float)

    :float-int-part :dec-int
    :frac (* "." :zero-prefixable-int)
    :zero-prefixable-int (* :d (any (+ :d (* "_" :d))))

    :exp (* (set "Ee") :float-exp-part)
    :float-exp-part (* (? (set "-+")) :zero-prefixable-int)

    :special-float (* (? (set "-+")) (+ "inf" "nan"))

    # Boolean

    :boolean (+ :true :false)
    :true    (* (set "Tt") (set "Rr") (set "Uu") (set "Ee"))
    :false   (* (set "Ff") (set "Aa") (set "Ll") (set "Ss") (set "Ee"))

    # Date and Time (RFC 3339)

    :date-time (+ :offset-date-time :local-date-time :local-date :local-time)

    :date-fullyear  (4 :d)
    :date-month     (2 :d)
    :date-mday      (2 :d)
    :time-delim     (set "Tt ")
    :time-hour      (2 :d)
    :time-minute    (2 :d)
    :time-second    (2 :d)
    :time-secfrac   (* "." (some :d))
    :time-numoffset (* (set "-+") :time-hour ":" :time-minute)
    :time-offset    (+ (set "Zz") :time-numoffset)

    :partial-time   (* :time-hour ":" :time-minute ":" :time-second (? :time-secfrac))
    :full-date      (* :date-fullyear "-" :date-month "-" :date-mday)
    :full-time      (* :partial-time :time-offset)

    :offset-date-time (* :full-date :time-delim :full-time)
    :local-date-time  (* :full-date :time-delim :partial-time)
    :local-date       :full-date
    :local-time       :partial-time

    # Array

    :array (* "[" (? :array-values) :ws-comment-nl "]")
    :array-values (+ (* :ws-comment-nl :val :ws-comment-nl "," :array-values) # Check this
                     (* :ws-comment-nl :val :ws-comment-nl (? ",")))

    :ws-comment-nl (any (+ :ws-char (* (? :comment) :nl)))

    # Inline Table

    :inline-table (* "{" :ws (? :inline-table-keyvals) :ws "}")
    :inline-table-sep (* :ws "," :ws)
    :inline-table-keyvals (* :keyval (? (* :inline-table-sep :inline-table-keyvals)))

    # Table

    :table (+ (* (constant array-table) :array-table)
              (* (constant std-table)   :std-table))

    :std-table (* "[" :ws :key :ws "]")

    :array-table (* "[[" :ws :key :ws "]]")})

(def toml (peg/compile toml-grammar))
