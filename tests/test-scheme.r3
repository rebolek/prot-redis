; CONFIGURATION: define your redis server ('rs) address here:
[url? rs: redis://192.168.211.10]

;;-----------------------
; port actions 
;;-----------------------

;========
; DELETE (FLUSH ALL, so DB is empty for testing)
;========

[delete rs]


;==========
;OPEN/CLOSE
;==========

[port? redis-port: rp: open rs]
[open? redis-port]
[port? close redis-port]
[not open? redis-port]


;========
; RENAME
;========

[
	write rs/wrongkey "some data"
	rename rs/wrongkey rs/goodkey
	"some data" = to string! read rs/goodkey
]


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


;========
; LIST
;========

[9 = write rs [RPUSH list1 "Merkur" "Venuše" "Země" "Mars" "Jupiter" "Saturn" "Uran" "Neptun" "Pluto"]]
[1 = delete rs/list1/Pluto/1]
[8 = length? read rs/list1]
['list = select query rs/list1 'type]
[delete rs/list1/1x4]
[1 = delete rs/list1]

;========
; HASH
;========

[write rs [HMSET hash1 name "Frodo" race "hobbit"]]
[equal? (map ["name" "Frodo" "race" "hobbit"]) map block-string read rs/hash1]
['hash = select query rs/hash1 'type]
[1 = delete rs/hash1/race]
[1 = delete rs/hash1]


;=======
; SET
;=======

[3 = write rs [SADD 'set1 "red" "green" "blue"]]
[equal? ["blue" "green" "red"] sort block-string read rs/set1] ; SORT needed as it seems that order is not guaranteed
[1 = delete rs/set1/red]

;============
; SORTED SET
;============

[3 = write rs [ZADD 'zset1 100 "Full" 0 "Nothing" 50 "Half"]]
[equal? ["Nothing" "Half" "Full"] block-string read rs/zset1]
[equal? 50 load read rs/zset1/Half]
[equal? ["Half"] block-string read rs/zset1/50]
[1 = delete rs/zset1]
[9 = write rs [ZADD 'zset1 58 "Merkur" 108 "Venuse" 150 "Zeme" 228 "Mars" 778 "Jupiter" 1424 "Saturn" 2867 "Uran" 4488 "Neptun" 5910 "Pluto"]]
[1 = delete rs/zset1/Pluto]
