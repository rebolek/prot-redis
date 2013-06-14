REBOL [
    Title: "Redis Actions"
    File: %prot-redis.r3
    Date: 13-6-2013
	Created: 13-6-2013
    Version: 0.1.0
    Author: "Boleslav Březovský"
	Purpose: "Extend Redis scheme with series! actions"
	To-Do: [
	]
	Notes: [
	]
	Bugs: [
	]
]

if in system/schemes 'redis [
	append system/schemes/redis/actor reduce/no-set [
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
				equal? type 'hash		[[HMSET key (flat-body-of value)]]
				equal? type 'set		[[SADD key value]]
				equal? type 'zset		[[ZADD key (value)]]
			]
			write redis-port reduce/only cmd redis-commands 
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
				equal? type 'hash		[[HMSET key (flat-body-of value)]]				
				equal? type 'set		[[SADD key value]]
				equal? type 'zset		[[ZADD key (value)]]
			]
			write redis-port reduce/only cmd redis-commands 
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
			write redis-port reduce/only cmd redis-commands
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
			key 		;  [ ANY-WORD! ANY-STRING! PATH! ]
			value 
		][
			write-key redis-port key value
		]
		
		pick: funct [
			redis-port 
			key 
		][
			read-key/convert redis-port key
		]
		
		select: funct [
			"Select key and return its value."
			redis-port 
			key 
		][
;			redis-port/spec/path: join #"/" key 
;			redis-port/state/key: key 
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
					write redis-port [SET :key ""]
					""
				]
				equal? type 'list	[
					write redis-port [LTRIM :key 0 0]
					write redis-port [LPOP :key]
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
				equal? type 'zset	[[ZCARD key]]
			] redis-commands 
			either empty? cmd [none][
				write redis-port cmd
			]
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
			either empty? cmd [none][
				write redis-port cmd
			]
		]
		
		copy: funct [
			redis-port 
		][
			pick redis-port redis-port/state/key
		]
		
		at: funct [
			redis-port 
			index 
		][
			redis-port/state/index: either index [index][none]
			redis-port 
		]
		
		index?: funct [
			redis-port 
		][
			redis-port/state/index
		]
	]
]
		
