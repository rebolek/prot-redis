Redis scheme for Rebol3

	Boleslav Březovský
	31-3-2013
	
# Introduction

This script provides Redis scheme for Rebol3. [Redis](http://www.redis.io) is key/value (NoSQL) database.
Rebol3 is newest version of [Rebol](http://www.rebol.com) programming language.
This script implements Redis as standard Rebol protocol that can be accessed using redis://redis-server notation.
This script uses [Ladislav's test framework](https://github.com/rebolsource/rebol-test).

## Direct control

	write redis://192.168.1.1 [ SET foo "bar" ]
	
This way you can send raw commands to Redis server. The block is not reduced.
(Words and path evaluation may be added later.)

You can also use `send-redis-cmd` function

	port: open redis://192.168.1.1
	send-redis-cmd port [ SET foo "bar" ]
	close port
	
## Port! actions

###WRITE

	write redis://192.168.1.1/foo "bar"			; sets key 'foo to "bar" (calls SET foo bar)
	
You can also use WRITE to set members in other types than string.

	write redis://192.168.1.1/list/1 "bar"		; set value of first member in key "list" to "bar"
	write redis://192.168.1.1/hash/field "bar"	; set value of field "field" in key "hash" to "bar"
	write redis://192.168.1.1/zset/bar 123		; set score of member "bar" in key "zset" to 123
	
###READ

	read redis://192.168.1.1/foo			; returns "bar"	(calls GET foo)

Read works will all Redis type. See table for returned values:

		string -> returns value as binary!
		list   -> returns length of a list
		hash   -> returns hash as map!
		set    -> returns all members in set as block!
		zset   -> returns length of sorted set
		
	
###QUERY - return informations about key

	query redis://192.168.1.1
	query redis://192.168.1.1/foo
	
Returns informations about key as object!

	name -> key name
	size -> key size (length of string or number of members)
	date -> expiration date or none!
	type -> Redis datatype

###DELETE - delete key or member in key or whole database

	delete redis://192.168.1.1
	delete redis://192.168.1.1/foo

###RENAME

Rename key. Both arguments are path!

	rename redis://192.168.1.1/old-key redis://192.168.1.1/new-key

###OPEN

Open port and return it.

	redis-port: open redis://192.168.1.1/foo

###OPEN?

Returns `TRUE` when port is open.

###CLOSE

Close port.

###CREATE

###UPDATE

### Port! actions table

<table border="1">
	<th>
		<td><code>string</code></td>
		<td><code>list</code></td>
		<td><code>hash</code></td>
		<td><code>set</code></td>
		<td><code>sorted set</code></td>
		<td><code>pub/sub</code></td>
	</th>
	<tr>
		<td><code>READ</code></td>
		<td><strong>binary!</strong></td>
		<td><strong>block!</strong></td>
		<td><strong>map!</strong></td>
		<td><strong>not implemented</strong></td>
		<td><strong>not implemented</strong></td>
		<td><strong>not implemented</strong></td>
	</tr>
	<tr>
		<td><code>WRITE</code></td>
		<td><strong>logic!</strong></td>
		<td>length as <strong>integer!</strong></td>
		<td><strong>logic!</strong></td>
		<td><strong>not implemented</strong></td>
		<td><strong>not implemented</strong></td>
		<td><strong>not implemented</strong></td>
	</tr>
	<tr>
		<td><code>QUERY</code></td>
		<td><strong>object!</strong></td>
		<td><strong>object!</strong></td>
		<td><strong>object!</strong></td>
		<td><strong>not implemented</strong></td>
		<td><strong>not implemented</strong></td>
		<td><strong>not implemented</strong></td>
	</tr>
	<tr>
		<td><code>DELETE</code></td>
		<td><strong>logic!</strong></td>
		<td><strong>logic!</strong></td>
		<td><strong>logic!</strong></td>
		<td><strong>not implemented</strong></td>
		<td><strong>not implemented</strong></td>
		<td><strong>not implemented</strong></td>
	</tr>
</table>

## Series! actions

Series action allows accessing Redis database like normal Rebol block. 
It is possible to access Redis' datatypes directly from Rebol, so you can APPEND to lists or sets.
All function use standard Rebol 1-based indexing and protocol automaticaly converts indexes to zero based.

**NOTE:** Because Redis database is different from Rebol block, 
some commands have slightly different meaning and may return different values than help string suggests!
Please, read the documentation carefully so you are aware of these differencies.

###SELECT

Select KEY and return its value. Key stays selected for further operations (APPEND, CLEAR etc)

	select redis-port 'list-key

This function works same for all Redis datatypes.	

###PICK

Return KEY's value. Does not select key.

	pick redis-port 'key

This function works same for all Redis datatypes.
	
###POKE

If KEY is valid key name, set it's value. If KEY is integer and list key is already selected, set value in that list key.

	poke redis-port 'name "Boleslav"
	select redis-port 'colours
	poke redis-port 1 "Blue"

###CLEAR

####list

Remove all elements.

	select redis-port 'colours
	clear redis-port

###APPEND

####list

Append value to end and return list.

	select redis-port 'colours
	append redis-port "Green"
	
###INSERT

####list

Insert value at the head of the list. 

**NOTE:** Redis cannot insert into list at index position, so `INSERT` is implemented as `RPUSH key value`.

###LENGTH?

####string

Return length of value.

	>> poke redis-port 'name "Boleslav"
	>> length? redis-port
	== 8

####list

Return number of elements in string.

	>> select redis-port 'colors
	>> poke redis-port ["red" "green" "blue"]
	>> length? redis-port
	== 3

###CHANGE

###REMOVE

###COPY

###FIND

###NEXT

###BACK

###AT

###SKIP

###EMPTY?

###HEAD

###HEAD?

###TAIL

###TAIL?

###INDEX?

###MODIFY

###PAST?
