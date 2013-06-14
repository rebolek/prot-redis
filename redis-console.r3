REBOL[]

do %prot-redis.r3
rs: redis://192.168.211.10
write rs/test "foo"

halt 