# Tomlin API

[tomlin/toml-&gt;janet](#tomlintoml-janet)

## tomlin/toml-&gt;janet

**function**  | [source][1]

```janet
(toml->janet input)
```

Convert a TOML-formatted string to a Janet data structure

Tomlin converts a TOML-formatted string to a Janet data structure. The
conversions between types in TOML and types created by Tomlin are set out
below:

```
TOML              Janet
===========================
comment           (ignored)
key               keyword
string            string
integer           int/s64
float             number
boolean           boolean
offset date-time  table
local date-time   table
local date        table
local time        table
array             array
standard table    table
inline table      struct
---------------------------
```

Comments are parsed but are not included in the returned data structure.

This function will raise an error if the string is invalid TOML.

[1]: src/tomlin.janet#L83

