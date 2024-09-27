(defn- escape [c]
  (parse (string `"` c `"`)))


(defn- unicode [& args]
  (if (one? (length args))
    (parse (string `"\u` (args 0) `"`))
    (parse (string/format `"\U%06x"`
                          (+ (blshift (- (args 0) 0xd800) 10)
                             (- (args 1) 0xdc00)
                             0x10000)))))

(def- g
  (peg/compile ~{:main (* :element -1)
                 :element (* :s* :value :s*)
                 :value (+ :object :array :string :number :true :false :null)
                 :object (/ (* "{" (? (* :member (any (* "," :member)))) :s* "}") ,table)
                 :member (* :s* :string :s* ":" :element)
                 :array (/ (* "[" (? (* :element (any (* "," :element)))) :s* "]") ,array)
                 :string (% (* `"` :chars `"`))
                 :chars (any (+ :escape '(to (set `"\`))))
                 :escape (+ (/ '(* `\` (set `"\/bfnrt`)) ,escape) :unicode)
                 :unicode (/ (+ (* :hi-surr :lo-surr) (* `\u` '(4 :h))) ,unicode)
                 :hi-surr (* `\u` (number (* (set "Dd") (set "8AaBb") (2 :h)) 16))
                 :lo-surr (* `\u` (number (* (set "Dd") (set "CcDdEeFf") (2 :h)) 16))
                 :number (number (* :integer (? :fraction) (? :exponent)))
                 :integer (* (? "-") (+ (* (set "123456789") :d+) :d))
                 :fraction (* "." :d+)
                 :exponent (* (set "Ee") (? (set "+-")) :d+)
                 :true (* "true" (constant true))
                 :false (* "false" (constant false))
                 :null (* "null" (constant :null))}))

(defn decode
  ```
  Decodes JSON into a native Janet data structure
  ```
  [data]
  (def res (peg/match g data))
  (if (nil? res)
    (error "invalid JSON")
    (first res)))
