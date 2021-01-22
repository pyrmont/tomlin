(import testament :prefix "")
(import ../src/tomlin)
(import ../src/tomlin/json)


(defn- example [basename]
  (-> (string "test/examples/" basename ".toml")
      (slurp)
      (tomlin/toml->janet)))


(defn- one-line [s]
  (def replacer
    ~{:main (% (any (+ (/ (<- :nlws) " ")
                       (<- 1))))
      :nlws (* "\n" :s+)})
  (first (peg/match replacer s)))


(deftest basic
  (def expect
    (one-line
      `{ "database": { "data": { "type": "array",
                                 "value": [ { "type": "array",
                                              "value": [ { "type": "string",
                                                           "value": "delta" },
                                                         { "type": "string",
                                                           "value": "phi" } ] },
                                            { "type": "array",
                                              "value": [ { "type": "float",
                                                           "value": "3.14" } ] } ] },
                       "enabled": { "type": "boolean",
                                    "value": "true" },
                       "ports": { "type": "array",
                                  "value": [ { "type": "integer",
                                               "value": "8001" },
                                             { "type": "integer",
                                               "value": "8001" },
                                             { "type": "integer",
                                               "value": "8002" } ] },
                       "temp_targets": { "case": { "type": "float",
                                                   "value": "72" },
                                         "cpu": { "type": "float",
                                                  "value": "79.5" } } },
         "owner": { "dob": { "type": "offset datetime",
                             "value": "1979-05-27T07:32:00-08:00" },
                    "name": { "type": "string",
                              "value": "Tom Preston-Werner" } },
         "servers": { "alpha": { "ip": { "type": "string",
                                         "value": "10.0.0.1" },
                                 "role": { "type": "string",
                                           "value": "frontend" } },
                      "beta": { "ip": { "type": "string",
                                        "value": "10.0.0.2" },
                                "role": { "type": "string",
                                          "value": "backend" } } },
         "title": { "type": "string",
                    "value": "TOML Example" } }`))
  (def actual (json/janet->json (example "basic")))
  (is (= expect actual)))


(deftest comments
  (def actual (json/janet->json (example "comments")))
  (is (= "{  }" actual)))


(deftest numbers
  (def expect
    (one-line
      `{ "bin1": { "type": "integer", "value": "214" },
         "float1": { "type": "float", "value": "1" },
         "float2": { "type": "float", "value": "3.1415" },
         "float3": { "type": "float", "value": "-0.01" },
         "float4": { "type": "float", "value": "5e+22" },
         "float5": { "type": "float", "value": "1000000" },
         "float6": { "type": "float", "value": "-0.02" },
         "float7": { "type": "float", "value": "6.626e-34" },
         "float8": { "type": "float", "value": "224617.445991228" },
         "hex1": { "type": "integer", "value": "3735928559" },
         "hex2": { "type": "integer", "value": "3735928559" },
         "hex3": { "type": "integer", "value": "3735928559" },
         "infinite1": { "type": "float", "value": "inf" },
         "infinite2": { "type": "float", "value": "inf" },
         "infinite3": { "type": "float", "value": "-inf" },
         "int1": { "type": "integer", "value": "99" },
         "int2": { "type": "integer", "value": "42" },
         "int3": { "type": "integer", "value": "0" },
         "int4": { "type": "integer", "value": "-17" },
         "not1": { "type": "float", "value": "nan" },
         "not2": { "type": "float", "value": "nan" },
         "not3": { "type": "float", "value": "nan" },
         "oct1": { "type": "integer", "value": "342391" },
         "oct2": { "type": "integer", "value": "493" } }`))
  (def actual (json/janet->json (example "numbers")))
  (is (= expect actual)))


(deftest strings
  (def expect
    (string "{ \"lines\": { \"type\": \"string\", \"value\": \"The first newline is\\\\ntrimmed in raw strings.\\\\nAll other whitespace\\\\nis preserved.\\\\n\" }, "
              "\"path\": { \"type\": \"string\", \"value\": \"C:\\\\Users\\\\nodejs\\\\templates\" }, "
              "\"path2\": { \"type\": \"string\", \"value\": \"\\\\\\\\User\\\\admin$\\\\system32\" }, "
              "\"quoted\": { \"type\": \"string\", \"value\": \"Tom \\\"Dubs\\\" Preston-Werner\" }, "
              "\"re\": { \"type\": \"string\", \"value\": \"\\\\d{2} apps is t[wo]o many\" }, "
              "\"regex\": { \"type\": \"string\", \"value\": \"<\\\\i\\\\c*\\\\s*>\" }, "
              "\"str1\": { \"type\": \"string\", \"value\": \"I'm a string.\" }, "
              "\"str2\": { \"type\": \"string\", \"value\": \"You can \\\"quote\\\" me.\" }, "
              "\"str3\": { \"type\": \"string\", \"value\": \"Name\\\\tJos\\u00e9\\\\nLoc\\\\tSF.\" }, "
              "\"str4\": { \"type\": \"string\", \"value\": \"Roses are red\\\\nViolets are blue\" }, "
              "\"str5\": { \"type\": \"string\", \"value\": \"The quick brown fox jumps over the lazy dog.\" }, "
              "\"str6\": { \"type\": \"string\", \"value\": \"Here are fifteen quotation marks: \\\"\\\"\\\"\\\"\\\"\\\"\\\"\\\"\\\"\\\"\\\"\\\"\\\"\\\"\\\".\" }, "
              "\"str7\": { \"type\": \"string\", \"value\": \"\\\"This,\\\" she said, \\\"is just a pointless statement.\\\"\" } }"))
  (def actual (json/janet->json (example "strings")))
  (is (= expect actual)))


(deftest datetimes
  (def expect
    (one-line
      `{ "ld1": { "type": "local date",
                  "value": "1979-05-27" },
         "ldt1": { "type": "local datetime",
                   "value": "1979-05-27T07:32:00" },
         "ldt2": { "type": "local datetime",
                   "value": "1979-05-27T00:32:00.999999" },
         "lt1": { "type": "local time",
                  "value": "07:32:00" },
         "lt2": { "type": "local time",
                  "value": "00:32:00.999999" },
         "odt1": { "type": "offset datetime",
                   "value": "1979-05-27T07:32:00Z" },
         "odt2": { "type": "offset datetime",
                   "value": "1979-05-27T00:32:00-07:00" },
         "odt3": { "type": "offset datetime",
                   "value": "1979-05-27T00:32:00.999999-07:00" } }`))
  (def actual (json/janet->json (example "datetimes")))
  (is (= expect actual)))

(run-tests!)
