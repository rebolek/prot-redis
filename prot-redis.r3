REBOL [
    Title: "redis"
    File: %redis.r3
    Date: 30-Mar-2013
    Version: 0.0.1
    Author: "Boleslav Březovský"
;    Checksum: #{FB5370E73C55EF3C16FB73342E6F7ACFF98EFE97}
	To-Do: [
		"send-redis-cmd should accept Rebol datatypes and convert them for user."
	
		"Function that converts port/spec/path to key (currently uses next path)"
		"Rewrite: WRITE/READ lowlevel, use SERIES funcs instead (PICK for selecting key)"
	]
	History: [
		"Process return codes"
		"host without key plus block: command"	
		{
			Add shortcut function for:
				sync-write redis-port make-bulk-request reduce [ some-data ]
				parse-response redis-port/state/tcp-port/spec/redis-data
				
			TODO: Can't WRITE be used instead?	
		}
	]
]
comment {File redis.r3 created by PROM on 30-Mar-2013/8:55:56+1:00}

debug: none 

single?: func [
	"Return TRUE if block has one element"
	block [block!]
][
	equal? 1 length? block 
]

flat-body-of: funct [
	"Change all set-words to words"
	object [object!]
][
	parse body: body-of object [
		some [
			change [set key set-word! (key: to word! key)] key 
		|	any-type!
		]
	]
	body 
]

block-string: funct [
	"Convert all binary! values in block! to string! (modifies)"
	data	[block!]
][
	parse data [
		some [
			change [set value binary! (value: to string! value)] value 
		|	any-type!	
		]
	]
	data 
]

get-path: funct [
	"Check if port is open and return path as block!"
	redis-port [port!]
][
	if not open? redis-port [ open redis-port ]
	all [
		redis-port/spec/path
		parse next redis-port/spec/path "/"
	]
]

make-bulk: func [
	data	[ any-type! ] "Data to bulkize"
] [
	data: form data ; TODO: does it support all datatypes?
	rejoin [
		"$" length? data crlf 
		data crlf 
	]
]

make-bulk-request: func [
	args	[ block! ]	"Arguments for the bulk request"
	/local
] [
	append rejoin [ "*"	length? args crlf ] collect [ 
		foreach arg args [ keep make-bulk arg ] 
	]
]

parse-response: func [
	data [binary!]	"Response from Redis server"
	/local get-response length-rule length bulk-length block result 
] [
	get-response: has [response] [parse to string! next data [copy response to newline] response]
	length-rule: [
		copy length to crlf ( 
			length: to integer! to string! length 
			if equal? -1 length [return none]
		)
		crlf 
	]
	switch to char! data/1 [
		#"+" [get-response]				; STATUS reply
		#"-" [make error! get-response]	; ERROR reply
		#":" [to integer! get-response]	; INTEGER reply
		#"$" [							; BULK replies
			parse/all next data [
				length-rule 
				copy result length skip 
				crlf 
			]
			result 
		] 
		#"*" [							; MULTI BULK replies
			parse/all next data [
				length-rule (
					bulk-length: length 
					block: make block! length 
				)
				bulk-length [
					"$" length-rule 
					copy result length skip 
					crlf ( append block result )
				]
			]
			block 
		]
	]
]

parse-server-info: funct [
	"Parse return of INFO command"
	data 
][
	obj: object []
	section: word: value: none 
	body: copy []
	chars: charset [#"a" - #"z" #"A" - #"Z" #"_" #"=" #"," #"." #"-" #" "]
	integer: charset [#"0" - #"9"]
	alphanum: union chars integer 
	dot: #"."
	minus: #"-"
	parse probe  to string! data [
		some [
			"# " copy section to newline skip (body: copy [])
			some [
				copy word some alphanum ":" (type: string!)
				copy value [
					some integer dot some integer dot some integer (type: tuple!)
				|	some integer dot some integer [#"K" | #"M" | #"G"] (type: 'number)
				|	some integer dot some integer (type: decimal!)
				|	opt minus some integer	(type: integer!)
				|	some alphanum	
				] (
					if equal? type 'number [
						value: switch take/last value [
							#"K" [1'000 * to decimal! value]
							#"M" [1'000'000 * to decimal! value]
							#"G" [1'000'000'000 * to decimal! value]
						]
						type: integer!
					]
					value: to :type value
				)
				newline (repend body [to set-word! probe word value])
			] (
				repend obj [to set-word! section make object! body]
			)
			newline 
		]
	]
	obj
]

redis-type?: func [
	"Get Redis datatype of a key"
	redis-port 
	key 
][
	to lit-word! send-redis-cmd redis-port [ TYPE key ]
]

make-redis-error: func [
	message 
] [
	; the 'do arms the error!
	do make error! [
		type: 'Access
		id: 'Protocol
		arg1: message
	]
]

awake-handler: func [event /local tcp-port] [
	debug ["=== Client event:" event/type]
	tcp-port: event/port
	switch/default event/type [
		error [
			debug "error event received"
			tcp-port/spec/port-state: 'error
			true 
		]
		lookup [
			open tcp-port 
			false 
		]
		connect [
			debug "connected "
			write tcp-port tcp-port/locals
			tcp-port/spec/port-state: 'ready
			false 
		]
		read [
			debug ["^\read:" length? tcp-port/data]
			tcp-port/spec/redis-data: copy tcp-port/data
			clear tcp-port/data
			true 
		]
		wrote [
			debug "written, so read port"
			read tcp-port 
			false 
		]
		close [
			debug "closed on us!"
			tcp-port/spec/port-state: 'ready
			true 
		]
	] [true]
;	comment {
;the awake handler returns false normally unless we want to exit the wait which
;we do either as the default condition ( ie. unspecified event ),
;or with Error, Read and Close.
;        }
]

send-redis-cmd: func [
	"Send command to Redis server and parse response"
	redis-port 
	data "Data to send. Words and paths are evaluated."
][
	reduce/only data [append auth bgrewriteaof bgsave bitcount bitop blpop brpop brpoplpush client-kill client-list client-getname client-setname config-get config-set config-resetstat dbsize debug-object debug-segfault decr decrby del discard dump echo eval evalsha exec exists expire expireat flushall flushdb get getbit getrange getset hdel hexists hget hgetall hincrby hincrbyfloat hkeys hlen hmget hmset hset hsetnx hvals incr incrby incrbyfloat info keys lastsave lindex linsert llen lpop lpush lpushx lrange lrem lset ltrim mget migrate monitor move mset msetnx multi object persist pexpire pexpireat ping psetex psubscribe pttl publish punsubscribe quit randomkey rename renamenx restore rpop rpoplpush rpush rpushx sadd save scard script-exists script-flush script-kill script-load sdiff sdiffstore select set setbit setex setnx setrange shutdown sinter sinterstore sismember slaveof slowlog smembers smove sort spop srandmember srem strlen subscribe sunion sunionstore sync time ttl type unsubscribe unwatch watch zadd zcard zcount zincrby zinterstore zrange zrangebyscore zrank zrem zremrangebyrank zremrangebyscore zrevrange zrevrangebyscore zrevrank zscore zunionstore]
	sync-write redis-port make-bulk-request data 

;	probe to string! redis-port/state/tcp-port/spec/redis-data
	parse-response redis-port/state/tcp-port/spec/redis-data
]

sync-write: func [
	redis-port [port!]
	redis-cmd 
    /local tcp-port 
] [
	unless open? redis-port [
		open redis-port 
	]
	tcp-port: redis-port/state/tcp-port
	tcp-port/awake: :awake-handler
	either tcp-port/spec/port-state = 'ready [
		write tcp-port to binary! redis-cmd 
	][
		tcp-port/locals: copy redis-cmd 
	]
;        unless port? wait [tcp-port redis-port/spec/timeout] [
;            make-redis-error "redis timeout on tcp-port"
;        ]
	unless port? wait [tcp-port redis-port/spec/timeout] [
		make-redis-error "redis timeout on tcp-port"
	]
]


sys/make-scheme [
    name: 'redis
	title: "Redis Protocol"
	spec: make system/standard/port-spec-net [port-id: 6379 timeout: 5]

	actor: [
	
		open?: func [
			redis-port [port!]
		] [
			redis-port/state
        ]
		
		open: func [
			redis-port [port!]
			/local tcp-port 
		][
			if redis-port/state [return redis-port]
			if none? redis-port/spec/host [make-redis-error "Missing host address"]
			redis-port/state: context [
				tcp-port: none 
			]
			redis-port/state/tcp-port: tcp-port: make port! [
				scheme: 'tcp
				host: redis-port/spec/host
				port-id: redis-port/spec/port-id
				timeout: redis-port/spec/timeout
				ref: rejoin [tcp:// host ":" port-id]
				port-state: 'init
				redis-data: none 
			]
			comment {
					port/state/tcp-port now looks like this
					[ spec [object!] scheme [object!] actor awake state data locals ]
			}
			tcp-port/awake: none 
			open tcp-port 
			redis-port 
		]
		
		read: funct [
			redis-port [port!]
		][
			if path: get-path redis-port [ key: first path ]
			print ["*** PATH: " mold path ]
		;	type: to word! send-redis-cmd redis-port reduce [ 'TYPE key ] 
			type: probe redis-type? redis-port key 
			hash-body: zset-value: none 
			cmd: case [
				equal? type 'none		[ return none ]
				equal? type 'string		[  [ GET key ] ]
				all [ equal? type 'list	single? path ][  [ LLEN key ] ]
				equal? type 'list		[  [ LINDEX key path/2 ] ]
				hash-body: all [ equal? type 'hash single? path ][  [ HGETALL key ] ]
				equal? type 'set		[  [ SMEMBERS key ] ]
				equal? type 'hash		[  [ HGET key path/2 ] ]
				all [ equal? type 'zset single? path ][  [ ZCARD key ] ]
				zset-value: equal? type 'zset		[  [ ZSCORE key path/2 ] ]
			]
			response: send-redis-cmd redis-port cmd 
			case [
				hash-body [ 
					map collect [
						foreach [key value] response [
							keep reduce [to word! to string! key to string! value]
						]
					]
				]
				zset-value [ either response [ to integer! to string! response ][ response ] ]
				true [response]
			]
		]
		
		write: funct [
			redis-port [port!]
			value 
		][
			if path: get-path redis-port [ key: first path ]
			type: redis-type? redis-port key 
			request: case [
				all [ not path block? value ]	[ value ]											; VALUE is Redis code
				block? value 					[ compose [ RPUSH (key) (value) ] ]					; VALUE is block! and will be stored as LIST
				all [
					index: attempt [ to integer! second path ]
					equal? type 'list 
				] [
					reduce [ 'LSET key index value ] 
				]
				equal? type 'hash				[ compose [ HSET key (second path value) ] ]			; VALUE is field's value in hash
				equal? type 'zset				[ compose [ ZADD key (value second path) ] ]
				object? value 					[ compose [ HMSET key (flat-body-of value) ] ]	; VALUE is object! and will be stored as HASH -- THIS DOESN'T WORK BECAUSE OF WRITE
				true 							[ [ SET key value ] ] 						; VALUE will be stored as STRING (default action)
			]
			send-redis-cmd redis-port request 
		]	

		query: func [
;TODO: Add |FIELDS refinement
			redis-port [port!]
			/local path key response 
		][
			if path: get-path redis-port [ key: first path ]
			type: probe redis-type? redis-port key 
			case [
				none? path [ parse-server-info send-redis-cmd redis-port [ INFO ] ]	; TODO: query DB. What should it return? INFO?
				true [
					reduce/no-set [
						name: key 
						size: (
							response: read redis-port 
							either integer? response [ response ][ length? response ]
						)	
						date: (
							response: send-redis-cmd redis-port [ TTL key ]
							switch/default response [
								-1 [ none ]
							][
								local: now 
								local/time: local/time + response 
								local 
							]
						)
						type: ( to lit-word! send-redis-cmd redis-port [ TYPE key ] )
					]
				]
			]
		]
		
		delete: funct [
			redis-port [port!]
		][
			print "delete called"
			key: none 
			if path: get-path redis-port [ key: first path ]
			type: redis-type? redis-port key 
			request: case [
				none? path			[ [ FLUSHALL ] ]
				single? path		[ [ DEL key ] ]
				equal? type 'list	[ [ LREM key 1 second path ] ]	; TODO: delete redis://server/key/value/count 	???
				equal? type 'set	[ [ SREM key second path ] ]
				equal? type 'zset	[ [ ZREM key second path ] ]
				true				[ [ DEL key ] ]
			]
			send-redis-cmd redis-port request 
		]
		
		close: func [
			redis-port [port!]
		][
			close redis-port/state/tcp-port
			redis-port/state: none 
			redis-port 
		]
		
		append: func [
			redis-port [port!]
			data 
		][
			print ["append called with " data]
			true 
		]
		
		find: func [
			redis-port 
			value 
		][
			print ["Find called with " value]
		]
		
		poke: func [
			redis-port 
			key 
			value 
		][
			send-redis-cmd redis-port [ SET key value ]
		]
		
		pick: func [
			redis-port 
			key 
		][
			send-redis-cmd redis-port [ GET key ]
		]
	]
]

line: func [data] [print join data "==================================================="]

; ======= test
[
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

line "dialecting"

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

port: open redis://192.168.1.25/
append port "some data"
find port "value"
poke port #pokey "zx spectrum"
probe to string! pick port #pokey
close port 
probe query redis://192.168.1.25

print "Done."


