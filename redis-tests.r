; CONFIGURATION: define your redis server ('rs) address here:
[url? rs: redis://192.168.211.10]

;;-----------------------
; port actions 
;;-----------------------

;========
; DELETE (FLUSH ALL, so DB is empty for testing)
;========

[delete rs]


;========
; RENAME
;========

[
	write rs/wrongkey "some data"
	rename rs/wrongkey rs/goodkey
	"some data" = to string! read rs/goodkey
]

;==========
;OPEN/CLOSE
;==========

[port? redis-port: open rs]
[open? redis-port]
[port? close redis-port] ; ???
[not open? redis-port]



;;-----------------------
; datatypes 
;;-----------------------


;========
; STRING
;========

[write rs [SET key1 "value1"]]
["value1" = to string! write rs [GET key1]]
[1 = delete rs/key1]
[write rs/key1 "value2"]
["value2" = to string! read rs/key1]
['string = select query rs/key1 'type]

[port? redis-port: open rs]
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


;========
; LIST
;========

[3 = write rs [RPUSH list1 "red" "green" "blue"]]
[3 = length? read rs/list1]
; LIST - direct access
[write rs/list1/1 "yellow"]
["yellow" = to string! read rs/list1/1]
;[1 = delete rs/list1/1]
[1 = delete rs/list1]
[3 = write rs/list2 ["red" "green" "blue"]]
[3 = length? read rs/list2]
['list = select query rs/list2 'type]

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


;========
; HASH
;========

[write rs [HMSET hash1 name "Frodo" race "hobbit"]]
[equal? (map ["name" "Frodo" "race" "hobbit"]) read rs/hash1]
['hash = select query rs/hash1 'type]
[1 = delete rs/hash1]
; [write rs/hash1 map [name "Frodo" race "hobbit"]] ; -- impossible with current WRITE limitations
[poke redis-port 'obj1 object [name: "Gabriela" hair: 'brown]]
["Gabriela" = to string! pick redis-port 'name]
[append redis-port map ['legs 'long]]
[3 = length? redis-port]
[1 = delete rs/obj1/hair]
[2 = length? redis-port]

;=======
; SET
;=======

[3 = write rs [SADD 'set1 "red" "green" "blue"]]
[equal? ["blue" "green" "red"] sort block-string read rs/set1] ; SORT needed as it seems that order is not guaranteed
[equal? ["blue" "green" "red"] sort block-string select redis-port 'set1]
[1 = delete rs/set1/red]
[2 = length? redis-port]
[1 = append redis-port "yellow"]
[3 = length? redis-port]
[1 = append redis-port "orange"]
[4 = length? redis-port]

; TODO: how to implement POKE?
[4 = write rs [ SADD 'rok "1. jaro" "2. leto" "3. podzim" "4. zima"]] ; TODO: something's wrong with UTF-8
[equal? ["1. jaro" "2. leto" "3. podzim" "4. zima"] sort block-string select redis-port 'rok]

