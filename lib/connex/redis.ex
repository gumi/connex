defmodule Connex.Redis.Worker do
  @behaviour :poolboy_worker

  @impl :poolboy_worker
  def start_link({uri_or_redis_opts, connection_opts}) do
    uri_or_redis_opts = Connex.Pool.resolve(uri_or_redis_opts, Connex.Redis)
    connection_opts = Connex.Pool.resolve(connection_opts, Connex.Redis)
    Redix.start_link(uri_or_redis_opts, connection_opts)
  end
end

defmodule Connex.Redis.Helper do
  defmacro defredis(cmd, args) do
    margs = Enum.map(args, fn x -> {x, [], Connex.Redis.Helper} end)
    # :client_kill -> ["CLIENT", "KILL"]
    commands =
      cmd
      |> Atom.to_string()
      |> String.split("_")
      |> Enum.map(&String.upcase/1)

    cmd_bang = :"#{cmd}!"

    quote do
      def unquote(cmd)(
            pool_name_or_shards,
            unquote_splicing(margs),
            additional_commands \\ [],
            opts \\ []
          )
          when is_list(additional_commands) and is_list(opts) do
        Connex.Redis.query(
          pool_name_or_shards,
          [unquote_splicing(commands ++ margs) | additional_commands],
          opts
        )
      end

      def unquote(cmd_bang)(
            pool_name_or_shards,
            unquote_splicing(margs),
            additional_commands \\ [],
            opts \\ []
          )
          when is_list(additional_commands) and is_list(opts) do
        Connex.Redis.query!(
          pool_name_or_shards,
          [unquote_splicing(commands ++ margs) | additional_commands],
          opts
        )
      end
    end
  end
end

defmodule Connex.Redis do
  defp default_pool_args() do
    [worker_module: Connex.Redis.Worker, size: 10]
  end

  def child_spec(pool_name) do
    Connex.Pool.child_spec(Connex.Redis, pool_name, default_pool_args())
  end

  def child_specs() do
    Connex.Pool.child_specs(Connex.Redis, default_pool_args())
  end

  def run(pool_name_or_shards, fun) do
    Connex.Pool.run(Connex.Redis, pool_name_or_shards, fun)
  end

  def query(pool_name_or_shards_or_client, commands, opts \\ [])

  def query(pool_name, commands, opts) when is_atom(pool_name) do
    run(pool_name, fn conn -> Redix.command(conn, commands, opts) end)
  end

  def query({shard_name, shard_key}, commands, opts) when is_atom(shard_name) do
    run({shard_name, shard_key}, fn conn -> Redix.command(conn, commands, opts) end)
  end

  def query(client, commands, opts) do
    Redix.command(client, commands, opts)
  end

  def query!(pool_name_or_shards_client, commands, opts \\ [])

  def query!(pool_name, commands, opts) when is_atom(pool_name) do
    run(pool_name, fn conn -> Redix.command!(conn, commands, opts) end)
  end

  def query!({shard_name, shard_key}, commands, opts) when is_atom(shard_name) do
    run({shard_name, shard_key}, fn conn -> Redix.command!(conn, commands, opts) end)
  end

  def query!(client, commands, opts) do
    Redix.command!(client, commands, opts)
  end

  import Connex.Redis.Helper, only: [defredis: 2]

  # Server
  defredis(:bgrewriteaof, [])
  defredis(:bgsave, [])
  # [ip:port] [ID client-id] [TYPE normal|master|slave|pubsub] [ADDR ip:port] [SKIPME yes/no]
  defredis(:client_kill, [])
  defredis(:client_list, [])
  defredis(:client_getname, [])
  defredis(:client_pause, [:timeout])
  # ON|OFF|SKIP
  defredis(:client_reply, [:on_or_off_or_skip])
  defredis(:client_setname, [:connection_name])
  defredis(:command, [])
  defredis(:command_count, [])
  defredis(:command_getkeys, [])
  # [command-name ...]
  defredis(:command_info, [:command_name])
  defredis(:config_get, [:parameter])
  defredis(:config_rewrite, [])
  defredis(:config_set, [:parameter, :value])
  defredis(:config_resetstat, [])
  defredis(:dbsize, [])
  defredis(:debug_object, [:key])
  defredis(:debug_segfault, [])
  # [ASYNC]
  defredis(:flushall, [])
  # [ASYNC]
  defredis(:flushdb, [])
  # [section]
  defredis(:info, [])
  defredis(:lastsave, [])
  defredis(:monitor, [])
  defredis(:role, [])
  defredis(:save, [])
  # [NOSAVE|SAVE]
  defredis(:shutdown, [])
  defredis(:slaveof, [:host, :port])
  # [argument]
  defredis(:slowlog, [:subcommand])
  defredis(:sync, [])
  defredis(:time, [])

  # Lists
  # [key ...] timeout
  defredis(:blpop, [:key])
  # [key ...] timeout
  defredis(:brpop, [:key])
  defredis(:brpoplpush, [:source, :destination, :timeout])
  defredis(:lindex, [:key, :index])
  defredis(:linsert, [:key, :before_or_after, :pivot, :value])
  defredis(:llen, [:key])
  defredis(:lpop, [:key])
  # [value ...]
  defredis(:lpush, [:key, :value])
  defredis(:lpushx, [:key, :value])
  defredis(:lrange, [:key, :start, :stop])
  defredis(:lrem, [:key, :count, :value])
  defredis(:lset, [:key, :index, :value])
  defredis(:ltrim, [:key, :start, :stop])
  defredis(:rpop, [:key])
  defredis(:rpoplpush, [:source, :destination])
  # [value ...]
  defredis(:rpush, [:key, :value])
  defredis(:rpushx, [:key, :value])

  # Sets
  # [member ...]
  defredis(:sadd, [:key, :member])
  defredis(:scard, [:key])
  # [key ...]
  defredis(:sdiff, [:key])
  # [key ...]
  defredis(:sdiffstore, [:destination, :key])
  # [key ...]
  defredis(:sinter, [:key])
  # [key ...]
  defredis(:sinterstore, [:destination, :key])
  defredis(:sismember, [:key, :member])
  defredis(:smembers, [:key])
  defredis(:smove, [:source, :destination, :member])
  # [count]
  defredis(:spop, [:key])
  # [count]
  defredis(:srandmember, [:key])
  # [member ...]
  defredis(:srem, [:key, :member])
  # [key ...]
  defredis(:sunion, [:key])
  # [key ...]
  defredis(:sunionstore, [:destination, :key])
  # [MATCH pattern] [COUNT count]
  defredis(:sscan, [:key, :cursor])

  # Sorted Sets
  # [NX|XX] [CH] [INCR] score member [score member ...]
  defredis(:zadd, [:key])
  defredis(:zcard, [:key])
  defredis(:zcount, [:key, :min, :max])
  defredis(:zincrby, [:key, :increment, :member])
  # [key ...] [WEIGHTS weight [weight ...]] [AGGREGATE SUM|MIN|MAX]
  defredis(:zinterstore, [:destination, :numkeys, :key])
  defredis(:zlexcount, [:key, :min, :max])
  # [WITHSCORES]
  defredis(:zrange, [:key, :start, :stop])
  # [LIMIT offset count]
  defredis(:zrangebylex, [:key, :min, :max])
  # [LIMIT offset count]
  defredis(:zrevrangebylex, [:key, :max, :min])
  # [WITHSCORES] [LIMIT offset count]
  defredis(:zrangebyscore, [:key, :min, :max])
  defredis(:zrank, [:key, :member])
  # [member ...]
  defredis(:zrem, [:key, :member])
  defredis(:zremrangebylex, [:key, :min, :max])
  defredis(:zremrangebyrank, [:key, :start, :stop])
  defredis(:zremrangebyscore, [:key, :min, :max])
  # [WITHSCORES]
  defredis(:zrevrange, [:key, :start, :stop])
  # [WITHSCORES] [LIMIT offset count]
  defredis(:zrevrangebyscore, [:key, :max, :min])
  defredis(:zrevrank, [:key, :member])
  defredis(:zscore, [:key, :member])
  # [key ...] [WEIGHTS weight [weight ...]] [AGGREGATE SUM|MIN|MAX]
  defredis(:zunionstore, [:destination, :numkeys, :key])
  # [MATCH pattern] [COUNT count]
  defredis(:zscan, [:key, :cursor])

  # Hashes
  # [field ...]
  defredis(:hdel, [:key, :field])
  defredis(:hexists, [:key, :field])
  defredis(:hget, [:key, :field])
  defredis(:hgetall, [:key])
  defredis(:hincrby, [:key, :field, :increment])
  defredis(:hincrbyfloat, [:key, :field, :increment])
  defredis(:hkeys, [:key])
  defredis(:hlen, [:key])
  # [field ...]
  defredis(:hmget, [:key, :field])
  # [field value ...]
  defredis(:hmset, [:key, :field, :value])
  defredis(:hset, [:key, :field, :value])
  defredis(:hsetnx, [:key, :field, :value])
  defredis(:hstrlen, [:key, :field])
  defredis(:hvals, [:key])
  # [MATCH pattern] [COUNT count]
  defredis(:hscan, [:key, :cursor])

  # Strings
  defredis(:append, [:key, :value])
  # [start end]
  defredis(:bitcount, [:key])

  # [GET type offset] [SET type offset value] [INCRBY type offset increment] [OVERFLOW WRAP|SAT|FAIL]
  defredis(:bitfield, [:key])
  # [key ...]
  defredis(:bitop, [:operation, :destkey, :key])
  # [start] [end]
  defredis(:bitpos, [:key, :bit])
  defredis(:decr, [:key])
  defredis(:decrby, [:key, :decrement])
  defredis(:get, [:key])
  defredis(:getbit, [:key, :offset])
  defredis(:getrange, [:key, :start, :end])
  defredis(:getset, [:key, :value])
  defredis(:incr, [:key])
  defredis(:incrby, [:key, :increment])
  defredis(:incrbyfloat, [:key, :increment])
  # [key ...]
  defredis(:mget, [:key])
  # [key value ...]
  defredis(:mset, [:key, :value])
  # [key value ...]
  defredis(:msetnx, [:key, :value])
  defredis(:psetex, [:key, :milliseconds, :value])
  # [EX seconds] [PX milliseconds] [NX|XX]
  defredis(:set, [:key, :value])
  defredis(:setbit, [:key, :offset, :value])
  defredis(:setex, [:key, :seconds, :value])
  defredis(:setnx, [:key, :value])
  defredis(:setrange, [:key, :offset, :value])
  defredis(:strlen, [:key])

  # Keys
  # [key ...]
  defredis(:del, [:key])
  defredis(:dump, [:key])
  # [key ...]
  defredis(:exists, [:key])
  defredis(:expire, [:key, :seconds])
  defredis(:expireat, [:key, :timestamp])
  defredis(:keys, [:pattern])
  # [COPY] [REPLACE] [KEYS key [key ...]]
  defredis(:migrate, [:host, :port, :key_or_empty, :destination_db, :timeout])
  defredis(:move, [:key, :db])
  # [arguments [arguments ...]]
  defredis(:object, [:subcommand])
  defredis(:persist, [:key])
  defredis(:pexpire, [:key, :milliseconds])
  defredis(:pexpireat, [:key, :milliseconds_timestamp])
  defredis(:pttl, [:key])
  defredis(:randomkey, [])
  defredis(:rename, [:key, :newkey])
  defredis(:renamenx, [:key, :newkey])
  # [REPLACE]
  defredis(:restore, [:key, :ttl, :serialized_value])

  # [BY pattern] [LIMIT offset count] [GET pattern [GET pattern ...]] [ASC|DESC] [ALPHA] [STORE destination]
  defredis(:sort, [:key])
  # [key ...]
  defredis(:touch, [:key])
  defredis(:ttl, [:key])
  defredis(:type, [:key])
  # [key ...]
  defredis(:unlink, [:key])
  defredis(:wait, [:numslaves, :timeout])
  # [MATCH pattern] [COUNT count]
  defredis(:scan, [:cursor])

  # Eval
  # key [key ...] arg [arg ...]
  defredis(:eval, [:script, :numkeys])
  # key [key ...] arg [arg ...]
  defredis(:evalsha, [:sha1, :numkeys])
  defredis(:script_debug, [:yes_or_sync_or_no])
  # [sha1 ...]
  defredis(:script_exists, [:sha1])
  defredis(:script_flush, [])
  defredis(:script_kill, [])
  defredis(:script_load, [:script])

  # Transactions
  # Discard all commands issued after MULTI
  defredis(:discard, [])
  # Execute all commands issued after MULTI
  defredis(:exec, [])
  # Mark the start of a transaction block
  defredis(:multi, [])
  # Forget about all watched keys
  defredis(:unwatch, [])
  # [key ...] Watch the given keys to determine execution of the MULTI/EXEC block
  defredis(:watch, [:key])
end
