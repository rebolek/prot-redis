Redis scheme for Rebol3

	Boleslav Březovský
	9-5-2013
	
# Introduction

This script provides Redis scheme for Rebol3. [Redis](http://www.redis.io) is key/value (NoSQL) database.
Rebol3 is newest version of [Rebol](http://www.rebol.com) programming language.
This script implements Redis as standard Rebol protocol that can be accessed using redis://redis-server notation.
Redis protocol uses [Ladislav's test framework](https://github.com/rebolsource/rebol-test) for unit testing and is released under [Apache 2 license](http://www.apache.org/licenses/LICENSE-2.0.html).

## Direct control

	write redis://192.168.1.1 [ SET foo "bar" ]
	
This way you can send raw commands to Redis server. The block is not reduced.
(Words and path evaluation may be added later.)

You can also use `send-redis-cmd` function:

	port: open redis://192.168.1.1
	send-redis-cmd port [ SET foo "bar" ]
	close port
	
## Port! actions

###WRITE

For easy access you can use `WRITE` function.

To set key `foo` to value `bar`:

	write redis://192.168.1.1/foo "bar"
	
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
		zset   -> returns whole set ordered from lowest to highest score
		
	
###QUERY - return informations about key

	query redis://192.168.1.1
	query redis://192.168.1.1/foo
	
Return informations about key as object!.

	name -> key name
	size -> key size (length of string or number of members)
	date -> expiration date or none!
	type -> Redis datatype

###DELETE

Delete key or member in key or whole database.

	delete redis://192.168.1.1

Delete whole database (`FLUSHALL`).

	delete redis://192.168.1.1/foo

Delete one key (`REMOVE`).

	delete redis://192.168.1.1/foo/1

Delete first member in key.

###OPEN

Open port and return it.

	redis-port: open redis://192.168.1.1/foo


###OPEN?

Returns `TRUE` when port is open.

###CLOSE

Close port.

###CREATE

No information yet.

###RENAME

No information yet.

###UPDATE

No information yet.

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
		<td><strong>block!</strong></td>
		<td><strong>block!</strong></td>
		<td><strong>not implemented</strong></td>
	</tr>
	<tr>
		<td><code>WRITE</code></td>
		<td><strong>logic!</strong></td>
		<td>length as <strong>integer!</strong></td>
		<td><strong>logic!</strong></td>
		<td>length as <strong>integer!</strong></td>
		<td>length as <strong>integer!</strong></td>
		<td><strong>not implemented</strong></td>
	</tr>
	<tr>
		<td><code>QUERY</code></td>
		<td><strong>object!</strong></td>
		<td><strong>object!</strong></td>
		<td><strong>object!</strong></td>
		<td><strong>object!</strong></td>
		<td><strong>object!</strong></td>
		<td><strong>not implemented</strong></td>
	</tr>
	<tr>
		<td><code>DELETE</code></td>
		<td><strong>integer!</strong></td>
		<td><strong>integer!</strong></td>
		<td><strong>integer!</strong></td>
		<td><strong>integer!</strong></td>
		<td><strong>integer!</strong></td>
		<td><strong>not implemented</strong></td>
	</tr>
</table>

## Series! actions

Series action allows accessing Redis database like normal Rebol block. 
It is possible to access Redis' datatypes directly from Rebol, so you can APPEND to lists or sets.
All function use standard Rebol 1-based indexing and protocol automaticaly converts indexes to zero based.

**NOTE:** Because Redis database is different from Rebol block, 
some commands have slightly different meaning and may return different values than help string suggests.
Please, read the documentation carefully so you are aware of these differencies.

###SELECT

Select KEY and return its value. Key stays selected for further operations (`APPEND`, `CLEAR` etc)

	>> select redis-port 'list-key

This function works same for all Redis datatypes.	

###PICK

Return KEY's value. Does not select key.

	>> pick redis-port 'key

This function works same for all Redis datatypes.
	
###POKE

If KEY is valid key name, set it's value. If KEY is integer and list key is already selected, set value in that list key.

	>> poke redis-port 'name "Boleslav"
	>> select redis-port 'colours
	>> poke redis-port 1 "Blue"

###CLEAR

####string

Clear the string.

**NOTE:** String is rewritten with empty string.

####list

Remove all elements.

	>> select redis-port 'colours
	>> clear redis-port

####hash

Remove all fields and values.

###APPEND

####string

Append value at the end of the list

	>> poke redis-port 'key "Redis"
	>> append redis-port "Rebol"
	>> pick redis-port 'key
	== "RedisRebol"

####list

Append value to end and return list.

	>> select redis-port 'colours
	>> append redis-port "Green"
	
###INSERT

####string

*NOT AVAILABLE:* Redis doesn't support insert for string values. It may be implemented later at protocol level. 

####list

Insert value at the head of the list. 

*NOTE:* Redis cannot insert into list at index position, so **INSERT** is implemented as `RPUSH key value`.

####hash

####set

####zset

Add new elements to set. Argument must be block of [score member] pairs. Same as **APPEND**.

*NOT AVAILABLE*

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

####hash

Return number of fields in hash.

	>> select redis-port 'person
	>> poke redis-port map [name: "Boleslav" age: 37]
	>> length? redis-port
	== 2

####set

Return number of elements in set.

	>> write redis-server/beatles ['SADD John George Paul Mary John]
	>> select redis-port beatles
	>> length? redis-port
	== 4

####zset

Return number of elements in sorted set.

	>> write redis-server/score ['ZADD 0 John 0 George 1 Paul 10 Mary]
	>> select redis-port score
	>> length? redis-port
	== 4

###CHANGE

####string

Same as `POKE`.

####list

###REMOVE

###list

`LPOP:` Remove and get the first element in a list.

####set

`SPOP:` Remove and return a random member from a set.

###COPY

No information yet.

###FIND

No information yet.

###NEXT

No information yet.

###BACK

No information yet.

###AT

Sets **redis-port/state/index** to **index** . This value is used by some functions (**PICK** ...). Use **false** to reset index.

####string

**NOT AVAILABLE**

####list

Set position in list.

####hash

**NOTE:** Because `AT` accepts only **integer!**, **logic!** and **pair!**, it's not possible to select field in hash.

###SKIP

No information yet.

###INDEX?

Return **redis-port/state/index**.

	>> select redis-port 'list
	>> at redis-port 3
	>> index? redis-port
	== 2

###EMPTY?

No information yet.

###HEAD

No information yet.

###HEAD?

No information yet.

###TAIL

No information yet.

###TAIL?

No information yet.

###MODIFY

No information yet.

###PAST?

No information yet.

###Series! action table

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
		<td><code>SELECT</code></td>
		<td><strong>binary!</strong></td>
		<td><strong>block!</strong></td>
		<td><strong>map!</strong></td>
		<td><strong>block!</strong></td>
		<td><strong>block!</strong></td>
		<td><strong>not implemented</strong></td>
	</tr>
	<tr>
		<td><code>PICK</code></td>
		<td><strong>binary!</strong></td>
		<td><strong>block!</strong></td>
		<td><strong>map!</strong></td>
		<td><strong>block!</strong></td>
		<td><strong>binary!</strong> or <strong>block!</strong></td>
		<td><strong>not implemented</strong></td>
	</tr>
	<tr>
		<td><code>POKE</code></td>
		<td><strong>logic!</strong></td>
		<td>length as <strong>integer!</strong></td>
		<td><strong>logic!</strong></td>
		<td><strong>integer!</strong></td>
		<td><strong>not implemented</strong></td>
		<td><strong>not implemented</strong></td>
	</tr>
	<tr>
		<td><code>CLEAR</code></td>
		<td><strong>logic!</strong></td>
		<td><strong>logic!</strong></td>
		<td><strong>logic!</strong></td>
		<td><strong>not implemented</strong></td>
		<td><strong>not implemented</strong></td>
		<td><strong>not implemented</strong></td>
	</tr>
	<tr>
		<td><code>APPEND</code></td>
		<td>length as <strong>integer!</strong></td>
		<td>length as <strong>integer!</strong></td>
		<td><strong>logic!</strong></td>
		<td>length as <strong>integer!</strong></td>
		<td>number of added elements as <strong>integer!</strong></td>
		<td><strong>not implemented</strong></td>
	</tr>
	<tr>
		<td><code>INSERT</code></td>
		<td><strong>N/A</strong></td>
		<td>length as <strong>integer!</strong></td>
		<td><strong>logic!</strong></td>
		<td>length as <strong>integer!</strong></td>
		<td>number of added elements as <strong>integer!</strong></td>
		<td><strong>not implemented</strong></td>
	</tr>
	<tr>
		<td><code>LENGTH?</code></td>
		<td>string length as <strong>integer!</strong></td>
		<td>number of elements as <strong>integer!</strong></td>
		<td>number of fields as <strong>integer!</strong></td>
		<td>number of elements as <strong>integer!</strong></td>
		<td><strong>not implemented</strong></td>
		<td><strong>not implemented</strong></td>
	</tr>
	<tr>
		<td><code>REMOVE</code></td>
		<td><strong>not implemented</strong></td>
		<td>first member as <strong>binary!</strong></td>
		<td><strong>not implemented</strong></td>
		<td>random member as <strong>binary!</strong></td>
		<td><strong>not implemented</strong></td>
		<td><strong>not implemented</strong></td>
	</tr>
</table>