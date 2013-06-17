REBOL[]

rs: redis://192.168.211.10
;rs: redis://127.0.0.1

do %../prot-redis.r3

log-data: make string! 4000
log: func [data][
	append log-data probe data
	append log-data newline
]

log "set 100 keys (one by one)"
count: 100
log dt [
	repeat i count [
		write rs [SET (join "key" i) (join "value" i)]
	]
]

log "set 1000 keys (one by one)"
count: 1000
log dt [
	repeat i count [
		write rs [SET (join "key" i) (join "value" i)]
	]
]

log "run for one second"
nt: now/time/precise
i: 0
until [
	i: i + 1
	write rs [SET (join "key" i) (join "value" i)]
	(now/time/precise - nt) > 0:0:1
]
log rejoin ["Processed " i " keys."]

count: 10000
log "set 10000 keys (pipleline-limit = 1000)"
log dt [
	rp: open rs
	rp/spec/pipeline-limit: 1000
	repeat i count [
		write rp [SET (join "key" i) (join "value" i)]
	]
]

log "set 10000 keys (pipleline-limit = 10000)"
log dt [
	rp: open rs
	rp/spec/pipeline-limit: 10000
	repeat i count [
		write rp [SET (join "key" i) (join "value" i)]
	]
]

log "set 10000 keys (pipleline-limit = 0)"
log dt [
	rp: open rs
	rp/spec/pipeline-limit: 0
	repeat i count [
		write rp [SET (join "key" i) (join "value" i)]
	]
	read rp
]

log "set 100000 keys (pipleline-limit = 0)"
log dt [
	rp: open rs
	rp/spec/pipeline-limit: 0
	count: 100000
	repeat i count [
		write rp [SET (join "key" i) (join "value" i)]
	]
	read rp
]

log "set 100000 keys (pipleline-limit = 10000)"
log dt [
	rp: open rs
	rp/spec/pipeline-limit: 10000
	count: 100000
	repeat i count [
		write rp [SET (join "key" i) (join "value" i)]
	]
]


write %speed-result.txt log-data
halt 