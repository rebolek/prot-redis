; block! - dialect
[delete redis://192.168.1.25]
[write redis://192.168.1.25 [SET 'key1 "value1"]]
["value1" = to string! write redis://192.168.1.25 [GET 'key1]]

; series access function
; STRING
[port? redis-port: open redis://192.168.1.25]
[poke redis-port 'name "Redis"]
["Redis" = to string! pick redis-port 'name]
["Redis" = to string! select redis-port 'name]
['string = redis-type? redis-port]
[5 = length? redis-port]
[port? close redis-port]

; LIST 
[port? redis-port: open redis://192.168.1.25]
[none? select redis-port 'set1]
[empty? clear redis-port]
[1 = append redis-port "World"]
["World" = to string! pick redis-port 1]
['list = redis-type? redis-port]
[2 = insert redis-port "Hello"]
["Hello" = to string! pick redis-port 1]
[2 = length? redis-port]
[port? close redis-port]

; HASH