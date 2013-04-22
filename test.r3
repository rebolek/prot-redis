REBOL[]

do %prot-redis.r3
do %tests/run-recover.r

; ======= test
old-test: [
; DELETE (FLUSHALL)
probe delete redis://192.168.1.25
; SET command
probe write redis://192.168.1.25/foo rejoin [ "bar-" now ]
; QUERY
probe query redis://192.168.1.25/foo
; GET command
probe to string! read redis://192.168.1.25/foo
probe delete redis://192.168.1.25/foo 
probe write redis://192.168.1.25 [ EXISTS foo ]
probe read redis://192.168.1.25/foo

line "expiration"

; set expiration
probe write redis://192.168.1.25/expire "key will expire soon"
probe write redis://192.168.1.25 [ PEXPIRE expire 50 ] ; key will expire in 50 miliseconds
probe query redis://192.168.1.25/expire
wait .1
probe query redis://192.168.1.25/expire

; dialecting
probe length? to string! write redis://192.168.1.25 [ INFO ]
;probe append redis://192.168.1.25/block "one"

line "LIST"

; BLOCK -> LIST
probe write redis://192.168.1.25/block ["pinda" "bobik" "fifinka" "myspulin"]
probe read redis://192.168.1.25/block ;	returns block length
probe to string! read redis://192.168.1.25/block/1
probe write redis://192.168.1.25/block/1 "hurvinek"
probe to string! read redis://192.168.1.25/block/1
probe query redis://192.168.1.25/block
; TODO? DELETE - not directly supported in Redis

line "HASH"

;OBJECT, MAP -> HASH
;TODO: Rebol's WRITE supports [block! string! binary!] only. It should support other types also
;probe write redis://192.168.1.25/object object [name: "Spejbl" age: 34]
probe write redis://192.168.1.25 [ HMSET object name "Spejbl" age 34 ]
probe read redis://192.168.1.25/object	; returns MAP!
probe to string! read redis://192.168.1.25/object/age
probe write redis://192.168.1.25/object/name "Hurvinek"
probe to string! read redis://192.168.1.25/object/name

line "SET"

; SETS
probe write redis://192.168.1.25 [ SADD beat-set "John" "Paul" "George" "Ringo" "Paul"]
probe query redis://192.168.1.25/beat-set
probe block-string read redis://192.168.1.25/beat-set
probe delete redis://192.168.1.25/beat-set/John
probe block-string read redis://192.168.1.25/beat-set

line "SORTED SET"

; SORTED SETS 
probe write redis://192.168.1.25 [ ZADD scores 100 "Mario" 50 "Luigi" 42 "Peach" 23 "Bowser" 13 "Jason" ]
probe query redis://192.168.1.25/scores
probe read redis://192.168.1.25/scores
probe read redis://192.168.1.25/scores/Jason
probe write redis://192.168.1.25/scores/Jason "666"
probe read redis://192.168.1.25/scores/Jason
probe delete redis://192.168.1.25/scores/Jason
probe read redis://192.168.1.25/scores/Jason
probe query redis://192.168.1.25/scores
probe delete redis://192.168.1.25/scores
probe query redis://192.168.1.25/scores


]