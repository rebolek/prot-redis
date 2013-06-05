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
	"some data" = to string! parse-response read rs/goodkey
]

;==========
;OPEN/CLOSE
;==========

[port? redis-port: rp: open rs]
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
["value2" = to string! parse-response read rs/key1]
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
[3 = length? parse-response read rs/list1]
; LIST - direct access
[write rs/list1/1 "yellow"]
["yellow" = to string! parse-response read rs/list1/1]
;[1 = delete rs/list1/1]
[1 = delete rs/list1]
[3 = write rs/list2 ["red" "green" "blue"]]
[3 = length? parse-response read rs/list2]
['list = select query rs/list2 'type]

[port? redis-port: open rs]
[error? try [append redis-port "no key selected"]]
[none? select redis-port 'list]
[empty? clear redis-port]
[1 = append redis-port "World"]
["World" = to string! pick redis-port 'list/1]
['list = redis-type? redis-port]
[2 = insert redis-port "Hello"]
["Hello" = to string! pick redis-port 'list/1]
[2 = length? redis-port]

[4 = poke redis-port 'band ["John" "Paul" "George" "Pete"]]
[poke redis-port 'band/4 "Ringo"]
["Ringo" = to string! pick redis-port 'band/4]
[
	select redis-port 'band
	"John" = to string! remove redis-port
]


;========
; HASH
;========

[write rs [HMSET hash1 name "Frodo" race "hobbit"]]
[equal? (map ["name" "Frodo" "race" "hobbit"]) map block-string parse-response read rs/hash1]
['hash = select query rs/hash1 'type]
[1 = delete rs/hash1]
; [write rs/hash1 map [name "Frodo" race "hobbit"]] ; -- impossible with current WRITE limitations
[poke redis-port 'obj1 object [name: "Gabriela" hair: 'brown]]
[equal? "Gabriela" to string! pick redis-port 'obj1/name]
[equal? "brown" to string! select redis-port 'obj1/hair]
[1 = poke redis-port 'obj1/eyes "multicolor"]
[map? select redis-port 'obj1]
[3 = length? redis-port]
[append redis-port map ['legs 'long]]
[4 = length? redis-port]
[1 = delete rs/obj1/hair]
[3 = length? redis-port]
[insert redis-port map ['hair 'blond]]
[4 = length? redis-port]
;[port? at redis-port 'name]
;[equal? "Gabriela" to string! copy redis-port]
;[equal? "long" to string! copy at redis-port 'legs]

;=======
; SET
;=======

[3 = write rs [SADD 'set1 "red" "green" "blue"]]
[equal? ["blue" "green" "red"] sort block-string parse-response read rs/set1] ; SORT needed as it seems that order is not guaranteed
[equal? ["blue" "green" "red"] sort block-string select redis-port 'set1]
[1 = delete rs/set1/red]
[2 = length? redis-port]
[1 = append redis-port "yellow"]
[3 = length? redis-port]
[0 = append redis-port "yellow"]
[3 = length? redis-port]
[1 = insert redis-port "brown"]
[4 = length? redis-port]
[block? select redis-port 'set1]
[pick redis-port 'set1/yellow]
[found? find ["red" "green" "blue" "brown" "yellow"] to string! remove redis-port]


;============
; SORTED SET
;============

[3 = write rs [ZADD 'zset1 100 "Full" 0 "Nothing" 50 "Half"]]
[equal? ["Nothing" "Half" "Full"] block-string parse-response read rs/zset1]
[equal? 50 load parse-response read rs/zset1/Half]
[equal? ["Half"] block-string parse-response read rs/zset1/50]
[1 = delete rs/zset1]
[9 = write rs [ZADD 'zset1 58 "Merkur" 108 "Venuse" 150 "Zeme" 228 "Mars" 778 "Jupiter" 1424 "Saturn" 2867 "Uran" 4488 "Neptun" 5910 "Pluto"]]
[9 = length? select redis-port 'zset1]
[1 = delete rs/zset1/Pluto]
[8 = length? redis-port]
[1 = poke redis-port 'zset1/Slunce 0]
[1 = insert redis-port [414 "Ceres"]]
[4 = append redis-port [5910 "Pluto" 6482 "Haumea" 6850 "Makemake" 10123 "Eris"]]
[4 = length? parse-response read rs/zset1/100x500]
[3 = length? pick redis-port 'zset1/50x200]