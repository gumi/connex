defmodule Connex.Redis.Worker do
  @behaviour :poolboy_worker

  @impl :poolboy_worker
  def start_link({uri_or_redis_opts, connection_opts}) do
    Redix.start_link(uri_or_redis_opts, connection_opts)
  end
end

defmodule Connex.Redis.Helper do
  defmacro defredis(cmd, args) do
    margs = Enum.map args, fn(x) -> {x, [], Connex.Redis.Helper} end
    # :client_kill -> ["CLIENT", "KILL"]
    commands = cmd
               |> Atom.to_string()
               |> String.split("_")
               |> Enum.map(&String.upcase/1)
    cmd_bang = :"#{cmd}!"
    shard_cmd = :"shard_#{cmd}"
    shard_cmd_bang = :"shard_#{cmd}!"
    quote do
      def unquote(cmd)(pool_name, unquote_splicing(margs), additional_commands \\ [], opts \\ []) do
        Connex.Redis.query(pool_name, [unquote_splicing(commands ++ margs) | additional_commands], opts)
      end
      def unquote(cmd_bang)(pool_name, unquote_splicing(margs), additional_commands \\ [], opts \\ []) do
        Connex.Redis.query!(pool_name, [unquote_splicing(commands ++ margs) | additional_commands], opts)
      end
      def unquote(shard_cmd)(shard_name, shard_key, unquote_splicing(margs), additional_commands \\ [], opts \\ []) do
        Connex.Redis.shard_query(shard_name, shard_key, [unquote_splicing(commands ++ margs) | additional_commands], opts)
      end
      def unquote(shard_cmd_bang)(shard_name, shard_key, unquote_splicing(margs), additional_commands \\ [], opts \\ []) do
        Connex.Redis.shard_query!(shard_name, shard_key, [unquote_splicing(commands ++ margs) | additional_commands], opts)
      end
    end
  end
end

defmodule Connex.Redis do
  defp default_pool_args() do
    [worker_module: Connex.Redis.Worker,
     size: 10]
  end

  def child_spec(pool_name) do
    Connex.Pool.child_spec(Connex.Redis, pool_name, default_pool_args())
  end

  def child_specs() do
    Connex.Pool.child_specs(Connex.Redis, default_pool_args())
  end

  def run(pool_name, fun) do
    Connex.Pool.run(Connex.Redis, pool_name, fun)
  end

  def shard(shard_name, shard_key, fun) do
    Connex.Pool.shard(Connex.Redis, shard_name, shard_key, fun)
  end

  def query(pool_name, commands, opts \\ []) do
    run(pool_name, fn conn -> Redix.command(conn, commands, opts) end)
  end

  def query!(pool_name, commands, opts \\ []) do
    run(pool_name, fn conn -> Redix.command!(conn, commands, opts) end)
  end

  def shard_query(shard_name, shard_key, commands, opts \\ []) do
    shard(shard_name, shard_key, fn conn -> Redix.command(conn, commands, opts) end)
  end

  def shard_query!(shard_name, shard_key, commands, opts \\ []) do
    shard(shard_name, shard_key, fn conn -> Redix.command!(conn, commands, opts) end)
  end

  import Connex.Redis.Helper, only: [defredis: 2]

  # Server
  defredis :bgrewriteaof, []
  defredis :bgsave, []
  defredis :client_kill, [] # [ip:port] [ID client-id] [TYPE normal|master|slave|pubsub] [ADDR ip:port] [SKIPME yes/no]
  defredis :client_list, []
  defredis :client_getname, []
  defredis :client_pause, [:timeout]
  defredis :client_reply, [:on_or_off_or_skip] # ON|OFF|SKIP
  defredis :client_setname, [:connection_name]
  defredis :command, []
  defredis :command_count, []
  defredis :command_getkeys, []
  defredis :command_info, [:command_name] # [command-name ...]
  defredis :config_get, [:parameter]
  defredis :config_rewrite, []
  defredis :config_set, [:parameter, :value]
  defredis :config_resetstat, []
  defredis :dbsize, []
  defredis :debug_object, [:key]
  defredis :debug_segfault, []
  defredis :flushall, [] # [ASYNC]
  defredis :flushdb, [] # [ASYNC]
  defredis :info, [] # [section]
  defredis :lastsave, []
  defredis :monitor, []
  defredis :role, []
  defredis :save, []
  defredis :shutdown, [] # [NOSAVE|SAVE]
  defredis :slaveof, [:host, :port]
  defredis :slowlog, [:subcommand] # [argument]
  defredis :sync, []
  defredis :time, []

  # Lists
  defredis :blpop, [:key] # [key ...] timeout
  defredis :brpop, [:key] # [key ...] timeout
  defredis :brpoplpush, [:source, :destination, :timeout]
  defredis :lindex, [:key, :index]
  defredis :linsert, [:key, :before_or_after, :pivot, :value]
  defredis :llen, [:key]
  defredis :lpop, [:key]
  defredis :lpush, [:key, :value] # [value ...]
  defredis :lpushx, [:key, :value]
  defredis :lrange, [:key, :start, :stop]
  defredis :lrem, [:key, :count, :value]
  defredis :lset, [:key, :index, :value]
  defredis :ltrim, [:key, :start, :stop]
  defredis :rpop, [:key]
  defredis :rpoplpush, [:source, :destination]
  defredis :rpush, [:key, :value] # [value ...]
  defredis :rpushx, [:key, :value]

  # Sets
  defredis :sadd, [:key, :member] # [member ...]
  defredis :scard, [:key]
  defredis :sdiff, [:key] # [key ...]
  defredis :sdiffstore, [:destination, :key] # [key ...]
  defredis :sinter, [:key] # [key ...]
  defredis :sinterstore, [:destination, :key] # [key ...]
  defredis :sismember, [:key, :member]
  defredis :smembers, [:key]
  defredis :smove, [:source, :destination, :member]
  defredis :spop, [:key] # [count]
  defredis :srandmember, [:key] # [count]
  defredis :srem, [:key, :member] # [member ...]
  defredis :sunion, [:key] # [key ...]
  defredis :sunionstore, [:destination, :key] # [key ...]
  defredis :sscan, [:key, :cursor] # [MATCH pattern] [COUNT count]

  # Sorted Sets
  defredis :zadd, [:key] # [NX|XX] [CH] [INCR] score member [score member ...]
  defredis :zcard, [:key]
  defredis :zcount, [:key, :min, :max]
  defredis :zincrby, [:key, :increment, :member]
  defredis :zinterstore, [:destination, :numkeys, :key] # [key ...] [WEIGHTS weight [weight ...]] [AGGREGATE SUM|MIN|MAX]
  defredis :zlexcount, [:key, :min, :max]
  defredis :zrange, [:key, :start, :stop] # [WITHSCORES]
  defredis :zrangebylex, [:key, :min, :max] # [LIMIT offset count]
  defredis :zrevrangebylex, [:key, :max, :min] # [LIMIT offset count]
  defredis :zrangebyscore, [:key, :min, :max] # [WITHSCORES] [LIMIT offset count]
  defredis :zrank, [:key, :member]
  defredis :zrem, [:key, :member] # [member ...]
  defredis :zremrangebylex, [:key, :min, :max]
  defredis :zremrangebyrank, [:key, :start, :stop]
  defredis :zremrangebyscore, [:key, :min, :max]
  defredis :zrevrange, [:key, :start, :stop] # [WITHSCORES]
  defredis :zrevrangebyscore, [:key, :max, :min] # [WITHSCORES] [LIMIT offset count]
  defredis :zrevrank, [:key, :member]
  defredis :zscore, [:key, :member]
  defredis :zunionstore, [:destination, :numkeys, :key] # [key ...] [WEIGHTS weight [weight ...]] [AGGREGATE SUM|MIN|MAX]
  defredis :zscan, [:key, :cursor] # [MATCH pattern] [COUNT count]

  # Hashes
  defredis :hdel, [:key, :field] # [field ...]
  defredis :hexists, [:key, :field]
  defredis :hget, [:key, :field]
  defredis :hgetall, [:key]
  defredis :hincrby, [:key, :field, :increment]
  defredis :hincrbyfloat, [:key, :field, :increment]
  defredis :hkeys, [:key]
  defredis :hlen, [:key]
  defredis :hmget, [:key, :field] # [field ...]
  defredis :hmset, [:key, :field, :value] # [field value ...]
  defredis :hset, [:key, :field, :value]
  defredis :hsetnx, [:key, :field, :value]
  defredis :hstrlen, [:key, :field]
  defredis :hvals, [:key]
  defredis :hscan, [:key, :cursor] # [MATCH pattern] [COUNT count]

  # Strings
  defredis :append, [:key, :value]
  defredis :bitcount, [:key] # [start end]
  defredis :bitfield, [:key] # [GET type offset] [SET type offset value] [INCRBY type offset increment] [OVERFLOW WRAP|SAT|FAIL]
  defredis :bitop, [:operation, :destkey, :key] # [key ...]
  defredis :bitpos, [:key, :bit] # [start] [end]
  defredis :decr, [:key]
  defredis :decrby, [:key, :decrement]
  defredis :get, [:key]
  defredis :getbit, [:key, :offset]
  defredis :getrange, [:key, :start, :end]
  defredis :getset, [:key, :value]
  defredis :incr, [:key]
  defredis :incrby, [:key, :increment]
  defredis :incrbyfloat, [:key, :increment]
  defredis :mget, [:key] # [key ...]
  defredis :mset, [:key, :value] # [key value ...]
  defredis :msetnx, [:key, :value] # [key value ...]
  defredis :psetex, [:key, :milliseconds, :value]
  defredis :set, [:key, :value] # [EX seconds] [PX milliseconds] [NX|XX]
  defredis :setbit, [:key, :offset, :value]
  defredis :setex, [:key, :seconds, :value]
  defredis :setnx, [:key, :value]
  defredis :setrange, [:key, :offset, :value]
  defredis :strlen, [:key]

  # Keys
  defredis :del, [:key] # [key ...]
  defredis :dump, [:key]
  defredis :exists, [:key] # [key ...]
  defredis :expire, [:key, :seconds]
  defredis :expireat, [:key, :timestamp]
  defredis :keys, [:pattern]
  defredis :migrate, [:host, :port, :key_or_empty, :destination_db, :timeout] # [COPY] [REPLACE] [KEYS key [key ...]]
  defredis :move, [:key, :db]
  defredis :object, [:subcommand] # [arguments [arguments ...]]
  defredis :persist, [:key]
  defredis :pexpire, [:key, :milliseconds]
  defredis :pexpireat, [:key, :milliseconds_timestamp]
  defredis :pttl, [:key]
  defredis :randomkey, []
  defredis :rename, [:key, :newkey]
  defredis :renamenx, [:key, :newkey]
  defredis :restore, [:key, :ttl, :serialized_value] # [REPLACE]
  defredis :sort, [:key] # [BY pattern] [LIMIT offset count] [GET pattern [GET pattern ...]] [ASC|DESC] [ALPHA] [STORE destination]
  defredis :touch, [:key] # [key ...]
  defredis :ttl, [:key]
  defredis :type, [:key]
  defredis :unlink, [:key] # [key ...]
  defredis :wait, [:numslaves, :timeout]
  defredis :scan, [:cursor] # [MATCH pattern] [COUNT count]

  # Eval
  defredis :eval, [:script, :numkeys] # key [key ...] arg [arg ...]
  defredis :evalsha, [:sha1, :numkeys] # key [key ...] arg [arg ...]
  defredis :script_debug, [:yes_or_sync_or_no]
  defredis :script_exists, [:sha1] # [sha1 ...]
  defredis :script_flush, []
  defredis :script_kill, []
  defredis :script_load, [:script]
end
