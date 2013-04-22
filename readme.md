Redis scheme for Rebol3

	Boleslav Březovský
	31-3-2013
	
# Introduction

This script provides Redis scheme for Rebol3. There are three basic modes of operation.
Code is still alpha and there may be changes in implementation as the documentation for schemes writing in R3 is scarce.
However it's usable in current state.

## Direct control

	write redis://192.168.1.1 [ SET foo "bar" ]
	
This way you can send raw commands to Redis server. The block is not reduced.
(Words and path evaluation may be added later.)

You can also use `send-redis-cmd` function

	port: open redis://192.168.1.1
	send-redis-cmd port [ SET foo "bar" ]
	close port

NOTE: `send-redis-cmd` may do word! and path! lookup later (currently not implemented).
	
## Port! actions

###WRITE - SET key value

	write redis://192.168.1.1/foo "bar"			; sets key 'foo to "bar" (calls SET foo bar)
	
You can also use WRITE to set memebers in other types than string.

	write redis://192.168.1.1/list/1 "bar"		; set value of first member in key "list" to "bar"
	write redis://192.168.1.1/hash/field "bar"	; set value of field "field" in key "hash" to "bar"
	write redis://192.168.1.1/zset/bar 123		; set score of member "bar" in key "zset" to 123
	
###READ - GET key

	read redis://192.168.1.1/foo			; returns "bar"	(calls GET foo)

Read works will all Redis type. See table for returned values:

		string -> returns value as binary!
		list -> returns length of a list
		hash -> returns hash as map!
		set -> returns all memebers in set as block!
		zset -> returns length of sorted set
		
	
###QUERY - return informations about key

;	query redis://192.168.1.1		-- TODO: will send INFO command
	query redis://192.168.1.1/foo
	
Returns informations about key. Format is object!

	name -> key name
	size -> key size (length of string or number of members)
	date -> expiration date or none!
	type -> Redis datatype

DELETE - delete key or member in key or whole database

	delete redis://192.168.1.1/foo
	
## Series! actions

Series action allows accessing redis database like normal Rebol block. 
It's possible to access Redis' datatypes directly from rebol, so you can APPEND to lists or sets.
All function use standard rebol 1-based indexing and protocol automaticaly converts indexes to zero based.


###OPEN

Open port and return it.

	redis-port: open redis://192.168.1.1/foo

###SELECT

Select KEY and return it's value. Key stays selected for further operations (APPEND, CLEAR etc)

	select redis-port 'list-key

###PICK

Return KEY's value. Does not select key.

	pick redis-port 'key

###POKE

If KEY is valid key name, set it's value. If KEY is integer and list key is already selected, set value in that list key.

	poke redis-port 'name "Boleslav"
	select redis-port 'colours
	poke redis-port 1 "Blue"

###CLEAR

If the key is list, remove all elements

	select redis-port 'colours
	clear redis-port

###APPEND

If key is list, append value to end and return list.

	select redis-port 'colours
	append redis-port "Green"
	
###INSERT

If key is list, insert value at the head of the list. 
**NOTE:** Redis cannot insert into list at index position, so `INSERT` is implemented as `RPUSH key value`.