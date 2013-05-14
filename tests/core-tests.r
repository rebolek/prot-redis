; DELETE (FLUSH ALL, so DB is empty for testing)
; NOTE: define your redis server (rs) address here:
[delete rs: redis://192.168.1.25]

; STRING - dialect
[write rs [SET key1 "value1"]]
["value1" = to string! write rs [GET key1]]
; STRING - direct access
[1 = delete rs/key1]
[write rs/key1 "value2"]
["value2" = to string! read rs/key1]
['string = select query rs/key1 'type]

; LIST - dialect
[3 = write rs [RPUSH list1 "red" "green" "blue"]]
[3 = length? read rs/list1]
; LIST - direct access
[1 = write rs/list/1 "yellow"]
["yellow" = to string! rs/list/1]
;[1 = delete rs/list1/1]
[1 = delete rs/list1]
[3 = write rs/list2 ["red" "green" "blue"]]
[3 = length? read rs/list2]
['list = select query rs/list2 'type]

; HASH - dialect
[write rs [HMSET hash1 name "Frodo" race "hobbit"]]
[equal? (map ["name" "Frodo" "race" "hobbit"]) read rs/hash1]
; HASH - direct access
['hash = select query rs/hash1 'type]
[1 = delete rs/hash1]
; [write rs/hash1 map [name "Frodo" race "hobbit"]] ; -- impossible with current WRITE limitations

; SET - dialect
[3 = write rs [SADD 'set1 "red" "green" "blue"]]
[equal? ["green" "red" "blue"] block-string read rs/set1]

;;-----------------------
; port actions - RENAME
;;-----------------------

[
	write rs/wrongkey "some data"
	rename rs/wrongkey rs/goodkey
	"some data" = to string! read rs/goodkey
]

;;-----------------------
; series access function
;;-----------------------

; STRING
[port? redis-port: open rs]
[open? redis-port]
[poke redis-port 'name "Redis"]
["Redis" = to string! pick redis-port 'name]
["Redis" = to string! select redis-port 'name]
['string = redis-type? redis-port]
[5 = length? redis-port]
[10 = append redis-port "Rebol"]
["RedisRebol" = to string! pick redis-port 'name]

; NOTE: INSERT is not supproted in Redis directly. May be implemented later using multiple commands
; [15 = insert redis-port "Hello"]
; ["HelloRedisRebol" = to string! pick redis-port 'name]

[
	close redis-port
	not open? redis-port
]


; LIST 
[port? redis-port: open rs]
[error? try [append redis-port "no key selected"]]
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
[append redis-port map ['legs 'long]]
[3 = length? redis-port]

; SET

; SORTED SET

; PUB/SUB


; CLOSE PORT

[port? close redis-port]