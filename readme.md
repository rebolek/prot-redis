# Redis scheme for Rebol3

	Boleslav Březovský
	17-6-2013
	
# Introduction

This script provides Redis scheme for Rebol3. [Redis](http://www.redis.io) 
is key/value (NoSQL) database.
Rebol3 is newest version of [Rebol](http://www.rebol.com) programming language.
This script implements Redis as standard Rebol protocol that can be accessed using **redis://redis-server** notation.
Redis protocol uses [Ladislav's test framework](https://github.com/rebolsource/rebol-test) 
for unit testing and is released under [Apache 2 license](http://www.apache.org/licenses/LICENSE-2.0.html).

# How does it work?

**Redis** runs as server listening on TCP port, so access from **Rebol** is done using standard Rebol3 scheme.
All Rebol3 schemes are asynchronous - you need to call **WAIT** to fire up event system
( [See documentation for details](http://www.rebol.net/wiki/Event_System) ).
Because the connection speed between **Rebol** client and **Redis** server may vary, 
issuing one command at time can get very slow (for example with total roundtrip time of 250ms,
you are limited to only four operations per second).
To prevent this problem, **Redis** supports [pipelining](http://redis.io/topics/pipelining).
In pipelined mode the client can send more commands in one batch instead off sending one command at time.
Pipelining is supported by this scheme and defines how the protocol will behave.

# Usage

**Redis** protocol is implemented as **REBOL 3** module. To use it, 
import it using `import` function.

	>> import %prot.redis.reb

The module exports following functions:

* send-redis 
* write-key 
* read-key 

See below for detailed description of each command.

## Pipelining modes

There are basicaly three different modes of operation and they are defined by the length of the pipeline.
The length is stored in **redis/pipeline-limit**.
Pipeline limit is number of commands that will be send in one batch.

	>> redis/pipeline-limit
	== 0
	>> redis/pipeline-limit: 10'000
	== 10000

### Manual mode: redis/pipeline-limit = 0

User is in charge of sending commands to **Redis** server.
Commands must be processed with **WAIT** or **READ** (see below) functions.

### Simple mode: redis/pipeline-limit = 1

Each command is processed individually. 
To make things easier for beginners, this is default mode.

### Automatic mode: redis/pipeline-limit > 1

Commands are send after pipeline limit is reached.
**NOTE:** If you end the script and the queue is not empty, commands are **NOT** processed!
You may force the procsessing with **WAIT** or **READ** in such situation.

## Port functions

### OPEN

Open **Redis** port and clear command pipeline.

	>> redis-port: open redis://192.168.1.1


### OPEN?

Returns `TRUE` when port is open.


### WRITE

Write **Redis** command to the pipeline.
When the pipeline limit is reached, commands are send to the server.

	>> rs: open redis://redis-server
	>> write rs [SET foo 1]
	>> write rs [INCR foo]

**Write** has three modes of operations: basic, manual and automatic 
(see the pipelining modes).

In *Basic mode* **write** returns server's response as **binary!**.

In *Manual* and *Automatic* modes **write** returns pipeline length as **integer!**.

In *Automatic* mode, when the pipeline limit is hit, pipelined commands are 
send to server, **write** returns 0 and server's response is stored in 
**redis/data** (binary bulk data) and **redis/response** (parsed bulk data).

### READ

Read has two modes of operations:

#### Keys

Read value of given key.
Key is specified in the url in this format:

	>> read redis://server/key
	== #{...}
	>> read redis://server/key/member
	== #{...}

Protocol will first check for key type and then will return it's value.
This is not an atomic operation and is slower than direct access using commands.

#### Commands

Send commands in pipeline to the server and return response.
This is prefered mode of operations.

	>> write redis://redis-server [SET foo bar]
	>> read redis://redis-server
	== #{2B4F4B0D0A}

### READ

**READ** returns raw value of key as **binary!** in (multi)bulk format.
You can decode the data with **parse-response** function.
**READ** does check on key's type and sends appropriate command.

	>> write redis://192.168.1.1/foo "bar"
	>> read redis://192.168.1.1/foo
	== #{24330D0A6261720D0A}
	>> to string! parse-response read redis://192.168.1.1/foo
	== "bar"


### QUERY

	>> query redis://192.168.1.1
	>> query redis://192.168.1.1/foo
	
Return informations about key as `object!`.

	name -> key name
	size -> key size (length of string or number of members)
	date -> expiration date or none!
	type -> Redis datatype


### DELETE

Delete key or member in key or whole database.

Delete whole database - `FLUSHALL`:

	>> delete redis://192.168.1.1

Delete one key - `REMOVE`:

	>> delete redis://192.168.1.1/foo

Delete first member in list:

	>> delete redis://192.168.1.1/foo/1

### CLOSE

Close port.

### CREATE

No information yet.

### RENAME

No information yet.

### UPDATE

No information yet.


## Redis dialect

Redis dialect uses **Redis** commands. 
See the list of commands [here](http://redis.io/commands).
Commands are followed by values.
`get-word!` and `get-path!` can be used to get word or path value.
Paren! evaluates **Rebol** code.
All other datatypes are passed as-is.
For example, `SET foo bar` is same as `SET "foo" "bar"`.

	>> key: "foo"
	== "foo"
	>> value: "bar"
	== "bar"
	>> port: open redis://redis-server
	>> write port [SET key value]
	;; key: value
	>> write port [SET "key" "value"]
	;; key: value	
	>> write port [SET key :value]
	;; key: bar
	>> write port [SET :key :value]
	;; foo: bar
	>> write port [SET key (1 + 1)]
	;; key: 2

#### Why aren't word!s and path!s evaluated?

**Word!**s and **path!**s are not evaluated, to get their values 
you need to use **get-word!** or **get-path!** notation. 
This has its reasons. In **Redis**, composed keys in form of `user:1:name` 
are often used. Of course you are free to use this type of keys, 
but because this is **Rebol** client library, you have option 
to use `user/1/name` instead. This ways keys can be mapped directly 
to **Rebol** values on demand. 

Also, using **path!** is ***much*** faster than working with **string!**. 
**make path! [user 1 name]** runs about 8-9 faster than **rejoin ["user" 1 "name"]** on my machine.

## Exported functions

**Redis** protocol is implemented as **REBOL 3** module that exposes
following functions to user:

### SEND-REDIS

**SEND-REDIS** is a shorthand for `parse-reply write port data`. 
It sends request to **Redis** server and parses bulk reply.

	>> send-redis port [SET key value]
	== true
	>> send-redis port [GET key]       
	== "value"
	>> send-redis/binary port [GET key]
	== #{76616C7565}

### WRITE-KEY

Write value to **Redis** key. Function automatically selects appropriate
**Redis** command based on key and/or value datatypes.

### READ-KEY

Read value from **Redis** key. Function automatically selects appropriate
**Redis** command based on key datatype.

## Awake handler and callbacks

Because all Rebol3 ports are asynchronous by nature, if you want to execute 
your custom code, you need to change **AWAKE** handler. However because 
you mostly need to change **READ** actor, Redis scheme provides 
**SET-CALLBACK** function that will add your code to the **READ** 
without need for rewriting whole **AWAKE** handler.

### Usage

Pass port and function accepting one argument (**port!**) to **SET-CALLBACK**:

	>> port: open redis://redis-server
	>> set-callback port func [port][probe port/data] 
