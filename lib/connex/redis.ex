defmodule Connex.Redis.Helper do
  defmacro defredis(cmd, args, _dummy \\ nil) do
    cmd = cmd
          |> List.wrap()
          |> Enum.map(&Atom.to_string/1)
          |> Enum.join("_")
          |> String.to_atom()
    margs = Enum.map(args, fn arg -> {arg, [], Connex.Redis.Helper} end)

    quote do
      def unquote(cmd)(pool_name, unquote_splicing(margs)) do
        Connex.Redis.run(pool_name, fn client -> Exredis.Api.unquote(cmd)(client, unquote_splicing(margs)) end)
      end
    end
  end
end

defmodule Connex.Redis do
  defp default_pool_args() do
    [worker_module: Exredis,
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

  import Connex.Redis.Helper, only: [defredis: 2,
                                     defredis: 3]

  defredis :append, [:key, :value], &int_reply/1
  defredis :auth, [:password]
  defredis :bgrewriteaof, []
  defredis :bgsave, []
  defredis :bitcount, [:key, :start, :end], &int_reply/1
  defredis :bitcount, [:key], &int_reply/1
  defredis :bitop, [:operation, :destkey, :key]#, ...]
  defredis :blpop, [:key, :timeout]
  defredis :brpop, [:key, :timeout]
  defredis :brpoplpush, [:source, :destination, :timeout]
  defredis :dbsize, []
  defredis :decr, [:key], &int_reply/1
  defredis :decrby, [:key, :decrement], &int_reply/1
  defredis :del, [:key], &int_reply/1
  defredis :discard, []
  defredis :dump, [:key]
  defredis :echo, [:message]
  defredis :eval, [:script, :numkeys, :keys, :args]
  defredis :evalsha, [:scriptsha, :numkeys, :keys, :args]
  defredis :exec, []
  defredis :exists, [:key], &int_reply/1
  defredis :expire, [:key, :seconds], &int_reply/1
  defredis :expireat, [:key, :timestamp], &int_reply/1
  defredis :flushall, [], &sts_reply/1
  defredis :flushdb, []
  defredis :get, [:key]
  defredis :getbit, [:key, :offset], &int_reply/1
  defredis :getrange, [:key, :start, :end]
  defredis :getset, [:key, :value]
  defredis :hdel, [:key, :field], &int_reply/1#, ...]
  defredis :hexists, [:key, :field], &int_reply/1
  defredis :hget, [:key, :field]
  defredis :hgetall, [:key], fn x ->
    Enum.chunk(x, 2)
      |> Enum.map(fn [a, b] -> {a, b} end)
      |> Enum.into(Map.new)
  end
  defredis :hincrby, [:key, :field, :increment], &int_reply/1
  defredis :hincrbyfloat, [:key, :field, :increment]
  defredis :hkeys, [:key]
  defredis :hlen, [:key], &int_reply/1
  defredis :hmget, [:key, :field]#, ...]
  defredis :hmset, [:key, :vals], &sts_reply/1
  defredis :hset, [:key, :field, :value], &int_reply/1
  defredis :hsetnx, [:key, :field, :value], &int_reply/1
  defredis :hvals, [:key]
  defredis :incr, [:key], &int_reply/1
  defredis :incrby, [:key, :increment], &int_reply/1
  defredis :incrbyfloat, [:key, :increment]
  defredis :info, [:key]
  defredis :keys, [:pattern]
  defredis :lastsave, []
  defredis :lindex, [:key, :index]
  defredis :linsert, [:key, :before_after, :pivot, :value]
  defredis :llen, [:key]
  defredis :lpop, [:key]
  defredis :lpush, [:key, :value]#, ...]
  defredis :lpushx, [:key, :value]
  defredis :lrange, [:key, :start, :stop]
  defredis :lrem, [:key, :count, :value]
  defredis :lset, [:key, :index, :value]
  defredis :ltrim, [:key, :start, :stop]
  defredis :mget, [:key], &sts_reply/1#, ...]
  # defredis :migrate
  defredis :monitor, []
  defredis :move, [:key, :db]
  defredis :mset, [:vals], &sts_reply/1#, ...]
  defredis :msetnx, [:key, :value]#, ...]
  defredis :multi, []
  # defredis :object, []
  defredis :persist, [:key], &int_reply/1
  defredis :pexpire, [:key, :milliseconds], &int_reply/1
  defredis :pexpireat, [:key, :milli_timestamp], &int_reply/1
  defredis :ping, []
  defredis :psetex, [:key, :milliseconds, :value]
  defredis :psubscribe, [:pattern]#, ...]
  # defredis :pubsub, [:subcommand]
  defredis :pttl, [:key], &int_reply/1
  defredis :publish, [:channel, :message], &int_reply/1
  defredis :punsubscribe, [:pattern]#, ...]
  defredis :quit, []
  defredis :randomkey, []
  defredis :rename, [:key, :newkey], &sts_reply/1
  defredis :renamenx, [:key, :newkey], &int_reply/1
  defredis :restore, [:key, :ttl, :serialized_value]
  defredis :rpop, [:key]
  defredis :rpoplpush, [:source, :destination]
  defredis :rpush, [:key, :value]#, ...]
  defredis :rpushx, [:key, :value]#, ...]
  defredis :sadd, [:key, :member]#, ...]
  defredis :save, []
  defredis :scard, [:key]
  defredis [:script, :exists], [:shasum], &multi_int_reply/1
  defredis [:script, :flush], [], &sts_reply/1
  defredis [:script, :kill], []
  defredis [:script, :load], [:script]
  defredis :sdiff, [:key]#, ...]
  defredis :sdiffstore, [:destination, :key]#, ...]
  defredis :select, [:index]
  defredis :set, [:key, :value], &sts_reply/1
  defredis :setbit, [:key, :offset, :value], &int_reply/1
  defredis :setex, [:key, :seconds, :value], &sts_reply/1
  defredis :setnx, [:key, :value], &int_reply/1
  defredis :setrange, [:key, :offset, :value], &int_reply/1
  # defredis :shutdown, [:nosave, :save]
  defredis :sinter, [:key]#, ...]
  defredis :sinterstore, [:destination, :key]#, ...]
  defredis :sismember, [:key, :member]
  defredis :slaveof, [:host, :port]
  defredis :slowlog, [:subcommand]#, :argument]
  defredis :smembers, [:key]
  defredis :smove, [:source, :destination, :member]
  defredis :sort, [:key]#, :by_pattern]
  defredis :spop, [:key]
  defredis :srandmember, [:key]#, :count]
  defredis :srem, [:key, :member]#, ...]
  defredis :strlen, [:key], &int_reply/1
  defredis :subscribe, [:channel]#, ...]
  defredis :sunion, [:key]#, ...]
  defredis :sunionstore, [:destination, :key]#, ...]
  defredis :sync, []
  defredis :time, []
  defredis :ttl, [:key], &int_reply/1
  defredis :type, [:key]
  defredis :unsubscribe, [:channel]#, ...]
  defredis :unwatch, []
  defredis :watch, [:key]#, ...]
  defredis :zadd, [:key, :score, :member]#, ...]
  defredis :zcard, [:key]
  defredis :zcount, [:key, :min, :max]
  defredis :zincrby, [:key, :increment, :member]
  defredis :zinterstore, [:destination, :numkeys, :key]#, ...]
  defredis :zrange, [:key, :start, :stop]
  defredis :zrangebyscore, [:key, :start, :stop]
  defredis :zrank, [:key, :member]
  defredis :zrem, [:key, :member]#, ...]
  defredis :zremrangebyrank, [:key, :start, :stop]
  defredis :zremrangebyscore, [:key, :min, :max]
  defredis :zrevrange, [:key, :start, :stop]
  defredis :zrevrangebyscore, [:key, :min, :max]
  defredis :zrevrank, [:key, :member]
  defredis :zscore, [:key, :member]
  defredis :zunionstore, [:destination, :key]#, ...]
  # defredis :scan, [:cursor]
  # defredis :sscan, [:key, :cursor]
  # defredis :hscan, [:key, :cursor]
  # defredis :zscan, [:key, :cursor]
end
