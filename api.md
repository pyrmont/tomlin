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

Date-time objects are parsed into a table. The keys for the table are:

- **:hour** (_number_): the hour;
- **:mins** (_number_): the minutes;
- **:secs** (_number_): the seconds;
- **:secfracs** (_number_): the fractions of a second (optional); and
- **:offset** (_string_ / _table_): the timezone offset (optional).

The offset may be either the string `"Z"` or a table containing `:hour` and
`:mins` keys. The sign of the value of `:hour` indicates whether the timezone
is ahead or behind.

Comments are parsed but are not included in the returned data structure.

This function will raise an error if the string is invalid TOML.

[1]: src/tomlin.janet#L83

