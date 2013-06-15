REBOL [
    Title: "redis"
    File: %prot-redis.r3
    Date: 14-6-2013
	Created: 30-3-2013
    Version: 0.1.9
    Author: "Boleslav Březovský"
;    Checksum: #{FB5370E73C55EF3C16FB73342E6F7ACFF98EFE97}
	To-Do: [
		"`delete redis://192.168.1.1/list/1` to remove one member"
		"length? and other series actions should require key (redis://server/key)"
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
;debug: :print


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
	any [
		all [
			redis-port/state
			get in redis-port/state 'key
		]
		all [
			redis-port/spec/path
			load next redis-port/spec/path
		]
	]
]

make-bulk: func [
	data	[ any-type! ] "Data to bulkize"
	/local out
] [
	out: make binary! 64
	data: to binary! form data ; TODO: does it support all datatypes?
	repend out [
		"$" to string! length? data crlf 
		data crlf 
	]
]

make-bulk-request: func [
	args	[ block! ]	"Arguments for the bulk request"
	/local out
] [
	out: make binary! 64 * 32
	repend out rejoin [ "*"	to string! length? args crlf ]
	append out collect [ 
		foreach arg args [keep make-bulk arg] 
	]
]

parse-reply: func [
	data
	/binary	"Do not convert binary! to string!"
	/local
		message length status error integer bulk multi
		msg ret
][
	ret: make block! min 1000 system/schemes/redis/spec/pipeline-limit
	message: [
		copy msg to crlf (unless binary [msg: to string! msg])
		crlf
	]
	length: [
		copy len to crlf ( 
			len: load len 
			if equal? -1 len [len: none]
		)
		crlf 
	]
	status: 	[
		#"+" message (
			msg: to string! msg
			append ret either "OK" = msg [true][msg]
		)
	]
	error:		[
		#"-" message (
			append ret make-redis-error to string! msg
		)
	]
	integer:	[
		#":" message (
			append ret to integer! msg
		)
	]
	bulk:		[
		#"$" length
		copy msg len skip
		crlf (
			unless binary [msg: to string! msg]
			append ret msg
		)
	]
	multi:		[
		#"*" length (bulks: len)
		bulks bulk
	]
	parse data [
		some [
			status | error | integer | bulk | multi
		]
	]
	either single? ret [ret/1][ret]
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
	if name [
		to lit-word! parse-reply write redis-port [ TYPE :name ]
	]
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


process-pipeline: func [
	"Send pipelined commands to server and get response"
	redis-port	[port!]
][
	tcp-port: redis-port/state/tcp-port
	wait [tcp-port redis-port/spec/timeout]
	clear tcp-port/locals
	tcp-port/spec/redis-data
]

parse-dialect: funct [
	"Get value of get-word! and get-path! and evaluate paren!"
	dialect [block!]
	/local body key
][
	parse body: copy dialect [
		any [
			change [set key [get-word! | get-path!] (key: get key)] key 
		|	change [set key paren! (key: do key)] key 
		|	skip 
		]
	]
	body 
]



;===AWAKE HANDLER

awake-handler: funct [
	event
	/local port
][
;	print ["Awake-event:" event/type]
	port: event/port
	switch/default event/type [
		lookup [
			open port
		]
		connect [
			write event/port event/port/locals
		]
		wrote [
			read port
		]
		read  [
;			print ["^\read:" length? port/data]
			port/spec/redis-data: copy port/data
			clear port/data
			return true 
		]
		close [
			return true
		]
	] [
		print ["Unexpected event:" event/type]
		close port
		return true
	]
	false ; returned
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

write-key: funct [
	redis-port	[port!]
	key
	value
][
	if all [path? key 2 = length? key] [
		member: second key 
		key: first key 
	]
	type: redis-type?/key redis-port key 
	cmd: compose reduce/only case [
		all [equal? type 'none block? value]			[ [RPUSH key (value)] ]
		all [
			equal? type 'none
			any [object? value map? value]
		][
			 [HMSET key (flat-body-of value)]
		]
		equal? type 'none 								[ [SET key value] ]
		equal? type 'string					 			[ [SET key value] ]
		all [equal? type 'list integer? member]			[ [LSET key (member - 1) value] ]
		all [equal? type 'hash member]					[ [HSET key member value] ]
		equal? type 'set								[ [SADD key value] ]
		all [equal? type 'zset member]					[ [ZADD key value member] ]
	] redis-commands 
	write redis-port cmd
]

read-key: funct [
	"Return raw key's value."
	redis-port	[port!]
	key			[any-string! any-word! any-path!]
	/convert	"Convert data to Rebol type"
][
	member: none 
	if all [path? key 2 = length? key][
		member: second key 
		key: first key 
	]
	type: redis-type?/key redis-port key 
	post: none ; post process code
	cmd: reduce/only case [
		all [equal? type 'none none? key]					[ [KEYS '*] ]
		equal? type 'none									[ [] ]
		equal? type 'string									[ [GET key] ]
		all [equal? type 'list integer? member]				[ compose [LINDEX key (member - 1)] ]
		equal? type 'list 									[ [LRANGE key 0 -1] ]
		all [equal? type 'hash member]						[ [HGET key member] ]	
		equal? type 'hash									[ post: 'hash [HGETALL key] ]
		all [equal? type 'set member]						[ post: 'set [SISMEMBER key member] ]
		equal? type 'set									[ [SMEMBERS key] ]
		all [equal? type 'zset integer? member]				[ [ZRANGEBYSCORE key member member] ]
		all [equal? type 'zset pair? member]				[ [ZRANGEBYSCORE key member/1 member/2] ]				
		all [equal? type 'zset member]						[ post: 'score [ZSCORE key member] ]
		equal? type 'zset									[ [ZRANGE key 0 -1] ]
	] redis-commands 
	ret: either empty? cmd [none][
		write redis-port cmd
	]
	if all [ret convert] [
		ret: parse-reply ret
		ret: switch/default post [
			hash	[map ret]
			set		[to logic! ret]
			score	[load ret]
		][
			ret 
		]
	]
	ret
] 

do-redis: func [
	"Open Redis port, send all commands in data block and close port."
	redis-port	[port!]
	data		[block!]	"Redis commands to proceed"
][
	; TODO
]

sys/make-scheme [
    name: 'redis
	title: "Redis Protocol"
	spec: make system/standard/port-spec-net [
		port-id:		6379 
		timeout:		0:05
		pipeline-limit:	1
	]

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
				tcp-port:			none 
				pipeline-length:	0
				key: if redis-port/spec/path [load next redis-port/spec/path]
				index:				none 
			]
			redis-port/state/tcp-port: tcp-port: make port! [
				scheme: 'tcp
				host: redis-port/spec/host
				port-id: redis-port/spec/port-id
				timeout: redis-port/spec/timeout
				ref: rejoin [tcp:// host ":" port-id]
				port-state: 'init
				redis-data: none 
				locals: make binary! 10000
			]
			tcp-port/awake: :awake-handler ;:redis-port/awake ;none 
;			pipeline-length: 0
			open tcp-port 
			redis-port 
		]

		close: func [
			redis-port [port!]
		][
			if open? redis-port [
				either redis-port/state/pipeline-length > 0 [
					read redis-port
				][
					close redis-port/state/tcp-port
					redis-port/state: none 
				]	
			]
			redis-port 
		]
		
		read: func [
			"Read from port"
			redis-port [port!]
			/local key tcp-port
		][
			all [
				redis-port/spec/path
				open redis-port
				return read-key redis-port redis-port/state/key
			]
			tcp-port: redis-port/state/tcp-port
			wait [tcp-port redis-port/spec/timeout]
			clear tcp-port/locals
			redis-port/state/pipeline-length: 0
			also tcp-port/spec/redis-data close redis-port
		]
		
		write: func [
			"Write to pipeline"
			redis-port [port!]
			data [block! string! binary!]
			/local tcp-port size
		][
			unless open? redis-port [open redis-port]
			if string? data [
				data: reduce ['SET redis-port/state/key data]
			]
			redis-port/spec/path: none
			tcp-port: redis-port/state/tcp-port
			if none? tcp-port/locals [
				; Init pipeline buffer (100 bytes for each command in automatic or basic mode, 1 000 000 bytes for manual mode
				size: either zero? redis-port/spec/pipeline-limit [1'000'000][100 * redis-port/spec/pipeline-limit]
				tcp-port/locals: make binary! size
			]
			append tcp-port/locals make-bulk-request parse-dialect data
			redis-port/state/pipeline-length: redis-port/state/pipeline-length + 1
			switch/default redis-port/spec/pipeline-limit [
				0	[redis-port/state/pipeline-length]
				1	[read redis-port]
			][
				if redis-port/state/pipeline-length = redis-port/spec/pipeline-limit [read redis-port]
			]
		]	

		query: func [
;TODO: Add |FIELDS refinement
			redis-port [port!]
			/local key response 
		][
			all [
				key: redis-port/spec/path 
				key: load next key
				redis-port/spec/path: none
			] 
			case [
				none? key [
					parse-server-info write redis-port [INFO]
				]
				true [
					type: redis-type?/key redis-port key
					reduce/no-set [
						name: key 
						size: (
							response: read-key/convert redis-port key
							switch/default type [
								'hash [length? response]
							][response]
							; TODO: move this condition to SWITCH block above
							either integer? response [ response ][ length? response ]
						)	
						date: (
							response: parse-reply write redis-port [ TTL :key ]
							switch/default response [
								-1 [ none ]
							][
								local: now 
								local/time: local/time + response 
								local 
							]
						)
						type: (type)
					]
				]
			]
		]
		
		delete: func [
			redis-port [port!]
			/local key member index type cmd
		][
			all [
				key: redis-port/spec/path 
				key: load next key
				none? redis-port/spec/path: none
				path? key
				set [key member index] to block! key
			]
			type: redis-type?/key redis-port key 
			cmd: case [
				none? key						[ [ FLUSHALL ] ]
				all [word? member equal? type 'list][ 
					[ LREM :key :index :member ] 
				]
				all [pair? member equal? type 'list][
					[ LTRIM :key (to integer! member/1) (to integer! member/2) ]
				]
				all [member equal? type 'hash]	[ [ HDEL :key :member ] ]
				all [member equal? type 'set]	[ [ SREM :key :member ] ]
				all [member equal? type 'zset]	[ [ ZREM :key :member ] ]
				true							[ [ DEL :key ] ]
			]
			parse-reply write redis-port cmd
		]

		rename: funct [
			from 
			to 
		][
			redis-port: from 
			from: last parse/all from/spec/path "/"
			to: last parse/all to "/"
			write redis-port [RENAME :from :to]
		]
	]
]
