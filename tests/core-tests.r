; block! - dialect
[delete redis://192.168.1.25]
[write redis://192.168.1.25 [SET 'key1 "value1"]]
["value1" = to string! write redis://192.168.1.25 [GET 'key1]]

; series access function
; STRING key
[port? redis-port: open redis://192.168.1.25]
[poke redis-port 'name "Redis"]
["Redis" = to string! pick redis-port 'name]
["Redis" = to string! select redis-port 'name]
[port? close redis-port]

; LIST key
[port? redis-port: open redis://192.168.1.25]
[none? select redis-port 'set1]
[empty? clear redis-port]
[block? append redis-port "item1"]
["item1" = to string! pick redis-port 1]
[port? close redis-port]
