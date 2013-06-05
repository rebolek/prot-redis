REBOL[
	Title: "Async test"
]

do %prot-redis.r3

rs: redis://192.168.211.10
rp: make port! rs
rp/awake: :async-handler
open rp
write rp [ SET asynctest true ]
wait [ rp 3 ]

halt 