REBOL [
    Title: "redis"
    File: %redis.r3
    Date: 8-5-2013
	Created: 30-3-2013
    Version: 0.0.1
    Author: "Boleslav Březovský"
;    Checksum: #{FB5370E73C55EF3C16FB73342E6F7ACFF98EFE97}
	To-Do: [
		"send-redis-cmd: after lookup convert any-word! to word! (so #key, 'key, key:, key are same key) or not?"
		"send-redis-cmd should accept Rebol datatypes and convert them for user."
		"Is it possible to implement `delete redis://192.168.1.1/list/1` to remove one member?"
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
	Notes: [
{WRITE -
	WRITE block!	parse dialect and convert all Rebol values to Redis types
	WRITE string!	direct access (not yet implemented)
	WRITE binary!	write RAW bulk data
	
WRITE block! and binary! ignores path (key) - TODO: should it select database?	
}	
	]
	Bugs: [
		"read server/non-existent-key returns list of keys instead of none"
	]
]
comment {File redis.r3 created by PROM on 30-Mar-2013/8:55:56+1:00}

debug: none 

flat-body-of: funct [
	"Change all set-words to words"
	object [object! map!]
][
	parse body: body-of object [
		any [
			change [set key set-word! (key: to word! key)] key 
		|	skip 
		]
	]
	body 
]

block-string: funct [
	"Convert all binary! values in block! to string! (modifies)"
	data	[block!]
][
	parse data [
		any [
			change [set value binary! (value: to string! value)] value 
		|	skip 
		]
	]
	data 
]

get-key: funct [
	"Return selected key or NONE"
	redis-port [port!]
][
	all [
		redis-port/spec/path
		first parse next redis-port/spec/path "/"
	]
]

get-index: funct [
	"Return index or NONE"
	redis-port [port!]
][
	all [
		redis-port/spec/path
		key: second parse next redis-port/spec/path "/"
		any [attempt [to integer! key] key]
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
		foreach arg args [keep make-bulk arg] 
	]
]

parse-response: func [
	data [none! binary!]	"Response from Redis server"
	/local get-response length-rule length bulk-length block result ret 
] [
	unless data [return none]
	get-response: has [response] [parse to string! next data [copy response to newline] response]
	length-rule: [
		copy length to crlf ( 
			length: to integer! to string! length 
			if equal? -1 length [return none]
		)
		crlf 
	]
	ret: switch to char! data/1 [
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
	switch/default ret [
		"OK"		[true]
	][
		ret 
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
	parse to string! data [
		some [
			"# " copy section to newline skip (body: copy [])
			some [
				copy word some alphanum #":" (type: string!)
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
				newline (repend body [to set-word! word value])
			] (
				repend obj [to set-word! section make object! body]
			)
			newline 
		]
	]
	obj
]

redis-type?: funct [
	"Get Redis datatype of a key"
	redis-port [port!]
	/key name "Name of key"
][
	unless key [name: get-key redis-port ]
	to lit-word! send-redis-cmd redis-port reduce [ 'TYPE name ]
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

redis-commands: [
	append auth bgrewriteaof bgsave bitcount bitop blpop brpop brpoplpush 
	client-kill client-list client-getname client-setname config-get 
	config-set config-resetstat dbsize debug-object debug-segfault decr 
	decrby del discard dump echo eval evalsha exec exists expire expireat 
	flushall flushdb get getbit getrange getset hdel hexists hget hgetall 
	hincrby hincrbyfloat hkeys hlen hmget hmset hset hsetnx hvals incr 
	incrby incrbyfloat info keys lastsave lindex linsert llen lpop lpush 
	lpushx lrange lrem lset ltrim mget migrate monitor move mset msetnx 
	multi object persist pexpire pexpireat ping psetex psubscribe pttl 
	publish punsubscribe quit randomkey rename renamenx restore rpop 
	rpoplpush rpush rpushx sadd save scard script-exists script-flush 
	script-kill script-load sdiff sdiffstore select set setbit setex setnx 
	setrange shutdown sinter sinterstore sismember slaveof slowlog smembers 
	smove sort spop srandmember srem strlen subscribe sunion sunionstore 
	sync time ttl type unsubscribe unwatch watch zadd zcard zcount zincrby 
	zinterstore zrange zrangebyscore zrank zrem zremrangebyrank 
	zremrangebyscore zrevrange zrevrangebyscore zrevrank zscore zunionstore 
]

send-redis-cmd: func [
	"Send command to Redis server and parse response (synhronous)"
	redis-port	[port!]
	data		[block!]	"Data to send. Words and paths are evaluated."
][
;	print ["Send-redis-cmd:" data]
	sync-write redis-port make-bulk-request data 
;	probe 
	parse-response redis-port/state/tcp-port/spec/redis-data
]

do-redis: func [
	"Open Redis port, send all commands in data block and close port."
	redis-port	[port!]
	data		[block!]	"Redis commands to proceed"
][
	; TODO
]

sync-write: func [
	"Synchronous write to Redis port"
	redis-port [port!]
	data 
    /local tcp-port 
] [
	unless open? redis-port [open redis-port]
	tcp-port: redis-port/state/tcp-port
	tcp-port/awake: :awake-handler
	either tcp-port/spec/port-state = 'ready [
		write tcp-port to binary! data 
	][
		tcp-port/locals: copy data 
	]
	unless port? wait [tcp-port redis-port/spec/timeout] [
		make-redis-error "redis timeout on tcp-port"
	]
	; NOYE: why the port cannot be closed here?
]

sys/make-scheme [
    name: 'redis
	title: "Redis Protocol"
	spec: make system/standard/port-spec-net [port-id: 6379 timeout: 5]

	actor: [
	
		open?: func [
			redis-port [port!]
		] [
			true? redis-port/state
        ]
		
		open: func [
			redis-port [port!]
			/local tcp-port 
		][
			if redis-port/state [return redis-port]
			if none? redis-port/spec/host [make-redis-error "Missing host address"]
			redis-port/state: context [
				tcp-port: none 
				key: get-key redis-port 
				index: none 
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

		close: func [
			redis-port [port!]
		][
			close redis-port/state/tcp-port
			redis-port/state: none 
			redis-port 
		]
		
		read: funct [
			"Read from port (currently SYNC only)"
			redis-port [port!]
		][
			key: get-key redis-port 
			type: redis-type? redis-port 
			
			open redis-port 
			ret: either index: get-index redis-port [
				pick redis-port index 
			][
				pick redis-port key 
			]
			close redis-port 
			ret 
		]
		
		write: funct [
			"Write to port (SYNC and ASYNC)"
			redis-port [port!]
			value [block! string! binary!]
		][
			either any-function? :redis-port/awake [
;				print "ASYNC"
			;  --- ASYNCHRONOUS OPERATION
				unless open? redis-port [cause-error 'Access 'not-open redis-port/spec/ref]
				if redis-port/state/state <> 'ready [http-error "Port not ready"]
				redis-port/state/awake: :port/awake
				parse-write-dialect redis-port value 
				do-request redis-port 
				redis-port 
			] [
			;  --- SYNCHRONOUS OPERATION
				key: get-key redis-port 
				either all [not key block? value][
					ret: send-redis-cmd redis-port value 
				][
					open redis-port 
					ret: either index: get-index redis-port [
						poke redis-port index value 
					][
						poke redis-port key value 
					]
					close redis-port 
				]
				ret 
			]		
		]	

		query: func [
;TODO: Add |FIELDS refinement
			redis-port [port!]
			/local key response 
		][
			key: get-key redis-port 
			type: redis-type? redis-port 
			case [
				none? key [ parse-server-info send-redis-cmd redis-port [ INFO ] ]	; TODO: query DB. What should it return? INFO?
				true [
					reduce/no-set [
						name: key 
						size: (
							response: switch/default type [
								'hash [length? response]
							][read redis-port]
							; TODO: move this condition to SWITCH block above
							either integer? response [ response ][ length? response ]
						)	
						date: (
							response: send-redis-cmd redis-port reduce [ 'TTL key ]
							switch/default response [
								-1 [ none ]
							][
								local: now 
								local/time: local/time + response 
								local 
							]
						)
;						type: ( to lit-word! send-redis-cmd redis-port reduce [ 'TYPE key ] )
						type: type 
					]
				]
			]
		]
		
		delete: funct [
			redis-port [port!]
		][
			key: get-key redis-port 
			index: get-index redis-port 
			type: redis-type? redis-port 
			request: case [
				none? key						[ [ FLUSHALL ] ]
				all [index equal? type 'list]	[ [ LREM key 1 index ] ]	; TODO: delete redis://server/key/value/count 	???
				all [index equal? type 'hash]	[ [ HDEL key index ] ]
				all [index equal? type 'set]	[ [ SREM key index ] ]
				equal? type 'zset				[ [ ZREM key index ] ]
				true							[ [ DEL key ] ]
			]
			send-redis-cmd redis-port reduce/only request redis-commands 
		]

		rename: funct [
			from 
			to 
		][
			redis-port: from 
			from: last parse/all from/spec/path "/"
			to: last parse/all to "/"
			send-redis-cmd redis-port reduce ['RENAME from to]
		]
		
; ===== series! actions
		
		append: funct [
			redis-port [port!]
			value 
		][
			unless key: get-key redis-port [make-redis-error "No key selected, SELECT key first."]
			type: redis-type? redis-port 
			cmd: case [
				equal? type 'none		[[RPUSH key value]]
				equal? type 'string		[[APPEND key value]]
				equal? type 'list		[[RPUSH key value]]
				equal? type 'hash		[compose [HMSET (key) (flat-body-of value)]]
				equal? type 'set		[[SADD key value]]
			]
			send-redis-cmd redis-port reduce/only cmd redis-commands 
		]
		
		insert: funct [
			redis-port [port!]
			value 
		][
			unless key: get-key redis-port [make-redis-error "No key selected, SELECT key first."]
			type: redis-type? redis-port 			
			cmd: case [
				equal? type 'none		[[LPUSH key value]]
;				equal? type 'string		[[]]		; --- there's no support in Redis for INSERT on strings
				equal? type 'list		[[LPUSH key value]]
				equal? type 'hash		[compose [HMSET (key) (flat-body-of value)]]				
				equal? type 'set		[[SADD key value]]
			]
			send-redis-cmd redis-port reduce/only cmd redis-commands 
		]
		
		remove: funct [
			redis-port [port!]
		][
			unless key: get-key redis-port [make-redis-error "No key selected, SELECT key first."]
			type: redis-type? redis-port 			
			cmd: case [
				equal? type 'none		[]
;				equal? type 'string		[[]]		; --- there's no support in Redis for INSERT on strings
				equal? type 'list		[[LPOP key]]
				equal? type 'hash		[]				
				equal? type 'set		[[SPOP key]]
			]
			send-redis-cmd redis-port reduce/only cmd redis-commands 		
		]
		
		find: func [
			redis-port 
			value 
		][
			print ["Find called with " value]
			true 
		]
		
		poke: funct [
			redis-port 
			key 
			value 
		][
			unless integer? key [
				redis-port/spec/path: join #"/" key 
				redis-port/state/key: key 
			]
			type: redis-type? redis-port 
			cmd: case [
				all [
					equal? type 'none
					block? value 
				][
					compose [RPUSH (key) (value)]
				]
				all [
					equal? type 'none
					any [object? value map? value]
				][
					 compose [HMSET (key) (flat-body-of value)]
				]
				equal? type 'none 				[reduce ['SET key value]]
				equal? type 'string 			[reduce ['SET key value]]
				all [
					equal? type 'list
					integer? key 
				][
					compose [LSET (redis-port/state/key) (key - 1) (value)]
				]
				equal? type 'set				[reduce ['SADD key value]]	; FIXME: does not clear previous values
			]
			send-redis-cmd redis-port cmd 
		]
		
		pick: funct [
			redis-port 
			key 
		][
			type: either redis-port/state/key [
				redis-type? redis-port 
			][
				redis-type?/key redis-port key 				
			]
			hash?: false 
			cmd: reduce/only case [
				all [equal? type 'none none? key]					[ [KEYS '*] ]
				equal? type 'none									[ [] ]
				equal? type 'string									[ [GET key] ]
				all [
					equal? type 'list 
					integer? key 
				][ 
					redis-port/state/index: key - 1
					key: get-key redis-port 
					[LINDEX key redis-port/state/index] 
				]
				equal? type 'list 									[ [LRANGE key 0 -1] ]
				equal? type 'set									[ [SMEMBERS key] ]
				all [
					equal? type 'hash 
					any [
						none? redis-port/state/key
						equal? key redis-port/state/key
					]
				][
					hash?: true 
					[HGETALL key]
				]	
				equal? type 'hash									[ [HGET redis-port/state/key key] ]
				equal? type 'zset									[ [ZRANGE key 0 -1] ]
				zset-value: equal? type 'zset						[ [ZSCORE redis-port/state/key key] ]
			] redis-commands 
			ret: either empty? cmd [none][send-redis-cmd redis-port cmd]
			if hash? [ret: map block-string ret]
			ret 
		]
		
		select: funct [
			"Select key and return its value."
			redis-port 
			key 
		][
			redis-port/spec/path: join #"/" key 
			redis-port/state/key: key 
			pick redis-port key 
		]
		
		clear: funct [
			"Clear selected key"
			redis-port 
		][
			key: redis-port/state/key
			type: redis-type? redis-port 
			ret: case [
				equal? type 'none	[[]]
				equal? type 'string [
					send-redis-cmd redis-port reduce ['SET key ""]
					""
				]
				equal? type 'list	[
					send-redis-cmd redis-port reduce ['LTRIM key 0 0]
					send-redis-cmd redis-port reduce ['LPOP key]
					[]
				]
				equal? type 'hash	[[]]
				equal? type 'set	[[]]
				equal? type 'zset	[[]]
			] 
		]
		
		length?: funct [
			redis-port 
		][
			key: redis-port/state/key
			type: redis-type? redis-port 
			cmd: reduce/only case [
				equal? type 'none	[[]]
				equal? type 'string [[STRLEN key]]
				equal? type 'list	[[LLEN key]]
				equal? type 'hash	[[HLEN key]]
				equal? type 'set	[[SCARD key]]
				equal? type 'zset	[[]]
			] redis-commands 
			either empty? cmd [none][send-redis-cmd redis-port cmd]
		]

		change: funct [
			redis-port 
			value 
		][
			key: redis-port/state/key
			index: redis-port/state/index
			type: redis-type? redis-port 
			cmd: reduce/only case [
				equal? type 'none				[[]]
				equal? type 'string 			[[SET key value]]
;				all [index equal? type 'list]	[[]]
				equal? type 'hash				[[]]
				equal? type 'set				[[]]
				equal? type 'zset				[[]]
			] redis-commands 
			either empty? cmd [none][send-redis-cmd redis-port cmd]		
		]
		
		at: funct [
			redis-port 
			index 
		][
			redis-port/state/index: either index [index][none]
		]
	]
]
