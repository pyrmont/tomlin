(import testament :prefix "")
(import ../src/tomlin)


(defn- example [basename]
  (-> (string "test/examples/" basename ".toml")
      (slurp)
      (tomlin/toml->table)))


(deftest basic
  (def expect
    {:title "TOML Example"
     :owner {:name "Tom Preston-Werner"
             :dob  {:year 1979 :month 5 :day 27
                    :hour 7 :mins 32 :secs 0
                    :offset {:hour -8 :mins 0}}}
     :database {:enabled true
                :ports [8001 8001 8002]
                :data [["delta" "phi"] [3.14]]
                :temp_targets {:cpu 79.5 :case 72.0}}
     :servers {:alpha {:ip "10.0.0.1" :role "frontend"}
               :beta  {:ip "10.0.0.2" :role "backend"}}})
  (def actual (example "basic"))
  (is (== expect actual)))


(deftest comments
  (is (== {} (example "comments"))))


(deftest strings
  (def expect
    {:str1 `I'm a string.`
     :str2 "You can \"quote\" me."
     :str3 "Name\tJos\u00E9\nLoc\tSF."
     :str4 "Roses are red\nViolets are blue"
     :str5 `The quick brown fox jumps over the lazy dog.`
     :str6 "Here are fifteen quotation marks: \"\"\"\"\"\"\"\"\"\"\"\"\"\"\"."
     :str7 "\"This,\" she said, \"is just a pointless statement.\""
     :path `C:\Users\nodejs\templates`
     :path2 `\\User\admin$\system32`
     :quoted `Tom "Dubs" Preston-Werner`
     :regex `<\i\c*\s*>`
     :re `\d{2} apps is t[wo]o many`
     :lines (string "The first newline is\n"
                    "trimmed in raw strings.\n"
                    "All other whitespace\n"
                    "is preserved.\n")})
  (def actual (example "strings"))
  (is (== expect actual)))


(deftest numbers
  (def expect
    {:int1 99
     :int2 42
     :int3 0
     :int4 -17
     :hex1 3735928559
     :hex2 3735928559
     :hex3 3735928559
     :oct1 342391
     :oct2 493
     :bin1 214
     :float1 1.0
     :float2 3.1415
     :float3 -0.01
     :float4 5e+22
     :float5 1e06
     :float6 -2E-2
     :float7 6.626e-34
     :float8 224617.445991228
     :infinite1 math/inf
     :infinite2 math/inf
     :infinite3 math/-inf
     :not1 math/nan
     :not2 math/nan
     :not3 math/nan})
  (def actual (example "numbers"))
  (is (== expect actual)))


(deftest datetimes
  (def expect
    {:odt1 {:year 1979 :month 5 :day 27 :hour 7 :mins 32 :secs 0 :offset "Z"}
     :odt2 {:year 1979 :month 5 :day 27 :hour 0 :mins 32 :secs 0
            :offset {:hour -7 :mins 0}}
     :odt3 {:year 1979 :month 5 :day 27 :hour 0 :mins 32 :secs 0 :secfracs 999999
            :offset {:hour -7 :mins 0}}
     :ldt1 {:year 1979 :month 5 :day 27 :hour 7 :mins 32 :secs 0}
     :ldt2 {:year 1979 :month 5 :day 27 :hour 0 :mins 32 :secs 0 :secfracs 999999}
     :ld1  {:year 1979 :month 5 :day 27}
     :lt1  {:hour 7 :mins 32 :secs 0}
     :lt2  {:hour 0 :mins 32 :secs 0 :secfracs 999999}})
  (def actual (example "datetimes"))
  (is (== expect actual)))


(run-tests!)
