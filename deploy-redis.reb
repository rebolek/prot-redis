REBOL[
	Title: "Deploy Redis server"
	Author: "Boleslav Brezovsky"
	Date: 21-1-2014
	Notes: {
		This script executes instrictions from [this page](http://redis.io/topics/quickstart)
		It expects that you already have redis-server in /usr/local/bin/
		It needs file %redis_init_script in same directory
	}
	Requirements: [
		%redis_init_script
		%redis.conf
	]
]

; read command line arguments

args: system/options/args
port: args/1


; make redis conf dirs

mkdir %/etc/redis
mkdir %/var/redis


; customize and copy init script - replace default port number

init-script: read %redis_init_script
replace init-script "6379" port
write join %/etc/init.d/redis_ port init-script

; customize and copy configuration file

config: read %redis.conf
replace config "daemonize no" "daemonize yes"
replace config "pidfile /var/run/redis.pid" rejoin ["pidfile /var/run/redis" port ".pid"]
replace config "port 6379" join "port " port
replace config {logfile ""} rejoin ["/var/log/redis_" port ".log"]
replace config "dir ./" join "dir /var/redis/" port

write rejoin [ %/etc/redis/ port %.conf ] config

; add redis init script to defualt runlevels

call rejoin ["update-rc.d redis_" port " defaults"]

; run redis instance

call rejoin ["/etc/init.d/redis_" port "  start"]