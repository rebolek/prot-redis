## Direct control

For direct access with port! actions like **READ**, **WRITE**, **DELETE**, you can use to keys and members using simple url! syntax:

	redis://redis-server
	redis://redis-server/key
	redis://redis-server/key/member

See port actions table below.

For direct sending Redis'commands use **WRITE**:

	>> write redis://192.168.1.1 [ SET foo "bar" ]
	
The block is not reduced.

You can also use `send-redis-cmd` function:

	>> port: open redis://192.168.1.1
	>> send-redis-cmd port [ SET foo "bar" ]
	>> close port
	
## Port! actions

###WRITE

For easy access you can use `WRITE` function.

To set key `foo` to value `bar`:

	>> write redis://192.168.1.1/foo "bar"
	
You can also use WRITE to set members in other types than string.

####list

Set value of first member in key "list" to "bar":

	>> write redis://192.168.1.1/list/1 "bar"

####hash

Set value of field "field" in key "hash" to "bar":

	>> write redis://192.168.1.1/hash/field "bar"

####set

####zset

set score of member "bar" in key "zset" to 123:

	>> write redis://192.168.1.1/zset/bar 123
	
###READ

**READ** returns raw value of key as **binary!** in (multi)bulk format.
You can decode the data with **parse-response** function.
**READ** does check on key's type and sends appropriate command.

	>> write redis://192.168.1.1/foo "bar"
	>> read redis://192.168.1.1/foo
	== #{24330D0A6261720D0A}
	>> to string! parse-response read redis://192.168.1.1/foo
	== "bar"


###QUERY - return informations about key

	>> query redis://192.168.1.1
	>> query redis://192.168.1.1/foo
	
Return informations about key as object!.

	name -> key name
	size -> key size (length of string or number of members)
	date -> expiration date or none!
	type -> Redis datatype

###DELETE

Delete key or member in key or whole database.

Delete whole database - `FLUSHALL`:

	>> delete redis://192.168.1.1

Delete one key - `REMOVE`:

	>> delete redis://192.168.1.1/foo

Delete first member in list:

	>> delete redis://192.168.1.1/foo/1


###OPEN

Open port and return it.

	>> redis-port: open redis://192.168.1.1/foo


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

If **key** argument is **any-word!** or **any-string!**, key is selected using `GET key`:

<table>
<th><td>Redis type</td><td>Rebol type</td><td>Description</td></th>
<tr><td>1.</td><td>string</td><td><strong>binary!</strong></td><td></td></tr>
<tr><td>2.</td><td>list</td><td><strong>block!</strong></td><td>Each member is returned as <strong>binary!</strong></td></tr>
<tr><td>3.</td><td>hash</td><td><strong>map!</strong></td><td></td></tr>
<tr><td>4.</td><td>set</td><td><strong>block!</strong></td><td></td></tr>
<tr><td>5.</td><td>sorted set</td><td><strong>block!</strong></td><td>Whole set ordered from lowest to highest score.</td></tr>
</table>

If **key** argument is **path!**, **PICK** returns member from set:

<table>
<th><td>index datatype</td><td>Redis command</td><td>Returned datatype</td><td>Comment</td></th>
<tr><td>list</td><td><strong>integer!</strong></td><td>LINDEX key index</td><td><strong>binary!</strong></td><td></td></tr>
<tr><td>hash</td><td><strong>any-string!</strong> | <strong>any-word!</strong></td><td>HGET key index</td><td><strong>binary!</strong></td><td></td></tr>
<tr><td>set</td><td><strong>any-string!</strong> | <strong>any-word!</strong></td><td>SISMEMBER key member</td><td><strong>logic!</strong></td><td>Returns <strong>TRUE</strong> if member exists in given set.</td></tr>
<tr><td>sorted set</td><td><strong>integer!</strong></td><td>ZRANGEBYSCORE key index index</td><td><strong>block!</strong></td><td></td></tr>
<tr><td>sorted set</td><td><strong>pair!</strong></td><td>ZRANGEBYSCORE key index/1 index/2</td><td><strong>block!</strong></td><td>Return all members with score in given range</td></tr>
<tr><td>sorted set</td><td><strong>any-string!</strong> | <strong>any-word!</strong></td><td>ZSCORE key member</td><td><strong>integer!</strong></td><td></td></tr>
</table>


###POKE

**POKE** will store value to a key. If key is **path!**, POKE can set value of members in key. See table below for details.



	>> poke redis-port 'name "Boleslav"
	>> select redis-port 'colours
	>> poke redis-port 1 "Blue"

<table>
<th><td>index datatype</td><td>value datatype</td><td>Redis command</td><td>Returned datatype</td><td>Comment</td></th>

<tr><td>string</td><td><strong>any-string!</strong> | <strong>any-word!</strong></td><td><strong>any-string!</strong> | <strong>any-word!</strong></td><td>SET key value</td><td><strong>integer!</strong></td><td></td></tr>

<tr><td>string</td><td><strong>integer!</strong></td><td colspan="4">Not implemented (may be used for bitsets)</td></tr>

<tr><td>list</td><td><strong>any-string!</strong> | <strong>any-word!</strong></td><td><strong>block!</strong></td><td>SET key value</td><td><strong>integer!</strong></td><td></td></tr>

<tr><td>list</td><td><strong>path!</strong></td><td><strong>any-string!</strong> | <strong>any-word!</strong></td><td>LSET key index value</td><td><strong>integer!</strong></td><td></td></tr>

<tr><td>hash</td><td><strong>any-string!</strong> | <strong>any-word!</strong></td><td><strong>map!</strong> | <strong>object!</strong></td><td>HSET key value</td><td><strong>integer!</strong></td><td></td></tr>

<tr><td>hash</td><td><strong>path!</strong></td><td><strong>any-string!</strong> | <strong>any-word!</strong></td><td>HSET key value</td><td><strong>integer!</strong></td><td></td></tr>

<tr><td>set</td><td><strong>any-string!</strong> | <strong>any-word!</strong></td><td colspan="4">Not implemented</tr>

<tr><td>set</td><td><strong>path!</strong><td><strong>any-string!</strong> | <strong>any-word!</strong></td><td>SADD key value</td><td><strong>integer!</strong></td><td></td></tr>

<tr><td>sorted set</td><td><strong>any-string!</strong> | <strong>any-word!</strong></td><td colspan="4">Not implemented</tr>

<tr><td>sorted set</td><td><strong>path!</strong></td><td><strong>integer!</strong></td><td>ZADD key value member</td><td><strong>integer!</strong></td><td></td></tr>

</table>

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

####hash

Add new elements to hash. Argument must be block of [field value] pairs.

####set

Add new elements to set.

####sorted set

Add new elements to sorted set. Argument must be block of [score member] pairs.

###INSERT

####string

*NOT AVAILABLE:* Redis doesn't support insert for string values. It may be implemented later at protocol level. 

####list

Insert value at the head of the list. 

*NOTE:* Redis cannot insert into list at index position, so **INSERT** is implemented as `RPUSH key value`.

####hash

Add new elements to hash. Argument must be block of [field value] pairs. Same as **APPEND**.

####set

Add new elements to set. Same as **APPEND**.

####sorted set

Add new elements to sorted set. Argument must be block of [score member] pairs. Same as **APPEND**.

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

####sorted set

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

####hash

####set

`SPOP:` Remove and return a random member from a set.

####sorted set

###COPY

No information yet.

###FIND

No information yet.

###NEXT

No information yet.

###BACK

No information yet.

###AT

Sets **redis-port/state/index** to **index** . This value is used by series actions that take only port! as argument. Use **false** to reset index.

####string

**NOT AVAILABLE**

####list

Set position in list.

####hash

**NOTE:** Because `AT` accepts only **integer!**, **logic!** and **pair!**, it's not possible to select field in hash.

####set

####sorted set

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