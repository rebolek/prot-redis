REBOL[]

do %prot-redis.reb
rs: redis://192.168.211.10

write rs/test "foo"

halt 