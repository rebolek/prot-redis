; CONFIGURATION: define your redis server ('rs) address here:
[url? rs: redis://192.168.211.10]

;;-----------------------
; port actions 
;;-----------------------

; set mode to BASIC

[1 = system/schemes/redis/spec/pipeline-limit: 1]

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
	"some data" = to string! parse-reply read rs/goodkey
]


;;-----------------------
; datatypes 
;;-----------------------


;========
; STRING
;========

[parse-reply write rs [SET key1 "value1"]]
["value1" = to string! parse-reply write rs [GET key1]]
[1 = delete rs/key1]
[parse-reply write rs/key1 "value2"]
["value2" = to string! parse-reply read rs/key1]
['string = select query rs/key1 'type]


;========
; LIST
;========

[9 = parse-reply write rs [RPUSH list1 "Merkur" "Venuše" "Země" "Mars" "Jupiter" "Saturn" "Uran" "Neptun" "Pluto"]]
[1 = delete rs/list1/Pluto/1]
[8 = length? parse-reply read rs/list1]
['list = select query rs/list1 'type]
[delete rs/list1/1x4]
[1 = delete rs/list1]

;========
; HASH
;========

[parse-reply write rs [HMSET hash1 name "Frodo" race "hobbit"]]
[equal? (map ["name" "Frodo" "race" "hobbit"]) map parse-reply read rs/hash1]
['hash = select query rs/hash1 'type]
[1 = delete rs/hash1/race]
[1 = delete rs/hash1]


;=======
; SET
;=======

[3 = parse-reply write rs [SADD 'set1 "red" "green" "blue"]]
[equal? ["blue" "green" "red"] sort parse-reply read rs/set1] ; SORT needed as the order is not guaranteed
[1 = delete rs/set1/red]

;============
; SORTED SET
;============

[3 = parse-reply write rs [ZADD 'zset1 100 "Full" 0 "Nothing" 50 "Half"]]
[equal? ["Nothing" "Half" "Full"] parse-reply read rs/zset1]
[equal? 50 load parse-reply read rs/zset1/Half]
[equal? "Half" parse-reply read rs/zset1/50]
[1 = delete rs/zset1]
[9 = parse-reply write rs [ZADD 'zset1 58 "Merkur" 108 "Venuse" 150 "Zeme" 228 "Mars" 778 "Jupiter" 1424 "Saturn" 2867 "Uran" 4488 "Neptun" 5910 "Pluto"]]
[1 = delete rs/zset1/Pluto]


;================================================
; MANUAL mode

; write 10 commands

[
	rp: open rs
	zero? rp/spec/pipeline-limit: 0
]
[
	repeat i 10 [write rp [set (join "foo" i) (join "bar" i)]]
	10 = rp/state/pipeline-length
]
[all parse-reply read rp]
[
	repeat i 10 [write rp [get (join "foo" i)]]
	10 = length? parse-reply read rp
]


;================================================
; AUTO mode

; set limit to 10, write 10 commands

[10 = rp/spec/pipeline-limit: 10]
[
	repeat i 10 [write rp [set (join "pat" i) (join "mat" i)]]
	not rp/state
]
; send only 5 commands
[
	repeat i 5 [write rp [set (join "bob" i) (join "bobek" i)]]
	5 = rp/state/pipeline-length
]
; force execution
[5 = length? parse-reply read rp]

; write 25 commands (two blocks by 10, rest manually)
[
	repeat i 25 [write rp [set (join "Štaflík" i) (join "Špagetka" i)]]
	5 = rp/state/pipeline-length
]
; force execution
[5 = length? parse-reply read rp]

; FORCE-CMD? mode
[rp/spec/force-cmd?: true]
[parse-reply write rp [SET foo bar]]
[
	write rp [GET foo]
	"bar" = parse-reply read rp
]