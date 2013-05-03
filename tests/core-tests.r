; DELETE (FLUSH ALL, so DB is empty for testing)
[delete redis://192.168.1.25]

; STRING - dialect
[write redis://192.168.1.25 [SET key1 "value1"]]
["value1" = to string! write redis://192.168.1.25 [GET key1]]
; STRING - direct access
[write redis://192.168.1.25/key1 "value2"]
["value2" = to string! read redis://192.168.1.25/key1]

; LIST - dialect
[3 = write redis://192.168.1.25 [RPUSH list1 "red" "green" "blue"]]
[3 = length? read redis://192.168.1.25/list1]
[3 = write redis://192.168.1.25/list2 ["red" "green" "blue"]]
[3 = length? read redis://192.168.1.25/list2]

;;-----------------------
; series access function
;;-----------------------

; STRING
[port? redis-port: open redis://192.168.1.25]
[open? redis-port]
[poke redis-port 'name "Redis"]
["Redis" = to string! pick redis-port 'name]
["Redis" = to string! select redis-port 'name]
['string = redis-type? redis-port]
[5 = length? redis-port]
[10 = append redis-port "Rebol"]
["RedisRebol" = to string! pick redis-port 'name]


; LIST 
[port? redis-port: open redis://192.168.1.25]
[none? select redis-port 'list]
[empty? clear redis-port]
[1 = append redis-port "World"]
["World" = to string! pick redis-port 1]
['list = redis-type? redis-port]
[2 = insert redis-port "Hello"]
["Hello" = to string! pick redis-port 1]
[2 = length? redis-port]

[4 = poke redis-port 'band ["John" "Paul" "George" "Pete"]]
[poke redis-port 4 "Ringo"]
["Ringo" = to string! pick redis-port 4]


; HASH

[poke redis-port 'obj1 object [name: "Gabriela" hair: 'brown]]
["Gabriela" = to string! pick redis-port 'name]

; SET

; SORTED SET

; PUB/SUB


; CLOSE PORT

[port? close redis-port]