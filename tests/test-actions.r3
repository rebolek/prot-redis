; CONFIGURATION: define your redis server ('rs) address here:
[url? rs: redis://192.168.211.10]

;;-----------------------
; datatypes 
;;-----------------------


;========
; STRING
;========

[port? redis-port: open rs]
[poke redis-port 'name "Redis"]
["Redis" = to string! pick redis-port 'name]
["Redis" = to string! select redis-port 'name]
['string = redis-type? redis-port]
[5 = length? rs/name]
[10 = append rs/name "Rebol"]
["RedisRebol" = to string! pick redis-port 'name]

; NOTE: INSERT is not supproted in Redis directly. May be implemented later using multiple commands
[15 = insert redis-port "Hello"]
["HelloRedisRebol" = to string! pick redis-port 'name]


;========
; LIST
;========

; LIST - direct access
[1 = delete rs/list1/1]
[3 = length? read rs/list1]

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

[write rs/hash1 map [name "Frodo" race "hobbit"]] ; -- impossible with current WRITE limitations
[poke redis-port 'obj1 object [name: "Gabriela" hair: 'brown]]
[equal? "Gabriela" to string! pick redis-port 'obj1/name]
[equal? "brown" to string! select redis-port 'obj1/hair]
[1 = poke redis-port 'obj1/eyes "multicolor"]
[map? select redis-port 'obj1]
[3 = length? redis-port]
[append redis-port map ['legs 'long]]
[4 = length? redis-port]
[3 = length? redis-port]
[insert redis-port map ['hair 'blond]]
[4 = length? redis-port]
[port? at redis-port 'name]
[equal? "Gabriela" to string! copy redis-port]
[equal? "long" to string! copy at redis-port 'legs]

;=======
; SET
;=======

[equal? ["blue" "green" "red"] sort block-string select redis-port 'set1]
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

[9 = length? select redis-port 'zset1]
[8 = length? redis-port]
[1 = poke redis-port 'zset1/Slunce 0]
[1 = insert redis-port [414 "Ceres"]]
[4 = append redis-port [5910 "Pluto" 6482 "Haumea" 6850 "Makemake" 10123 "Eris"]]
[4 = length? read rs/zset1/100x500]
[3 = length? pick redis-port 'zset1/50x200]
