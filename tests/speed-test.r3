REBOL[]

count: 1
rs: redis://192.168.211.10

do %prot-redis.r3

probe dt [loop count [write rs/randkey "asdf"]]
probe dt [rp: open rs loop count [poke rp 'randkey "asdf"] close rp]
probe dt [loop count [write rs [SET randkey "asdf"]]]
probe dt [rp: open rs loop count [send-redis-cmd rp [SET randkey "asdf"]] close rp]
print "direct 1"
probe dt [
	rp: open rs
	tcp-port: rp/state/tcp-port
	tcp-port/awake: :awake-handler
	loop count [
		either tcp-port/spec/port-state = 'ready [
			write tcp-port to binary! {SET randkey asdf}
		][
			tcp-port/locals: copy {SET randkey asdf}
		]
		parse-response rp/state/tcp-port/spec/redis-data
		
	]
	close rp	
]

print "direct 2."
rwrite: funct [
	rp
	data
][
	data: make-bulk-request data
	tcp-port: rp/state/tcp-port
	tcp-port/awake: :awake-handler
	either tcp-port/spec/port-state = 'ready [
		write tcp-port to binary! data
	][
		tcp-port/locals: copy data
	]
	unless port? wait [tcp-port rp/spec/timeout] [make-redis-error "redis timeout on tcp-port"]
	probe parse-response rp/state/tcp-port/spec/redis-data
]
probe dt [
	rp: open rs	
	loop count [rwrite rp [SET randkey asdf]]
	close rp	
]

print "direct 2(no wait)."
rwrite: funct [
	rp
	data
][
	data: make-bulk-request data
	tcp-port: rp/state/tcp-port
	tcp-port/awake: :awake-handler
	either tcp-port/spec/port-state = 'ready [
		write tcp-port to binary! data
	][
		tcp-port/locals: copy data
	]
;	unless port? wait [tcp-port rp/spec/timeout] [make-redis-error "redis timeout on tcp-port"]
	probe parse-response rp/state/tcp-port/spec/redis-data
]
probe dt [
	rp: open rs	
	loop count [rwrite rp [SET randkey asdf]]
	close rp	
]

print "bulk request"
probe dt [
	rp: open rs
	tcp-port: rp/state/tcp-port
	tcp-port/awake: :awake-handler
	loop count [
		either tcp-port/spec/port-state = 'ready [
			write tcp-port to binary! make-bulk-request [SET randkey asdf]
		][
			tcp-port/locals: copy make-bulk-request [SET randkey asdf]
		]
		parse-response rp/state/tcp-port/spec/redis-data
		
	]
	close rp	
]

probe dt [loop count [read rs/randkey]]
probe dt [rp: open rs loop count [pick rp 'randkey] close rp]
probe dt [loop count [write rs [GET randkey]]]
probe dt [rp: open rs loop count [send-redis-cmd rp [GET randkey]] close rp]
probe dt [
	rp: open rs
	tcp-port: rp/state/tcp-port
	tcp-port/awake: :awake-handler
	loop count [
		either tcp-port/spec/port-state = 'ready [
			write tcp-port to binary! {GET randkey}
		][
			tcp-port/locals: copy {GET randkey}
		]
		parse-response rp/state/tcp-port/spec/redis-data
		
	]
	close rp	
]
halt 