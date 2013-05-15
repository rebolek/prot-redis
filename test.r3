REBOL[]

do %prot-redis.r3
do %tests/test-framework.r

do-redis-tests: has [
	flags result log-file summary script-checksum
] [
	; TODO: invent own flags (low priority)
	; Check if we run R3 or R2.
	set 'flags pick [
		[#64bit #r3only #r3]
		[#32bit #r2only]
	] found? in system 'catalog

	; calculate script checksum
	script-checksum: checksum/method read %prot-redis.r3 'sha1

	print "Testing ..."
	result: do-recover %redis-tests.r flags script-checksum
	set [log-file summary] result

	print ["Done, see the log file:" log-file]
	print summary
]

do-redis-tests
halt 