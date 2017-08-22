# Connex

Pooling and sharding connections.

## Example

```elixir
config :connex, Connex.Redis,
  pools:
    # <pool_name>: {<poolboy_configuration>, <Arguments passed to Redix.start_link/2>}
    # <poolboy_configuration> is defaulted the value as [worker_module: Connex.Redis.Worker, size: 10]
    [pool1: {[], {[database: 0], []}},
     pool2: {[], {[database: 1], []}},
     pool3: {[], {[database: 2], []}}],
  shards:
    # <shard_name>: [<pool_name>, ...]
    [shard1: [:pool1, :pool2, :pool3],
     shard2: [:pool2, :pool3]]

config :my_app,
  redis: :pool1

config :my_app2,
  redis_shard: :shard1
```

```elixir
  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      ...
    ]
    children = children ++ Connex.Redis.child_specs()

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
```

```elixir
pool_name = Application.fetch_env!(:my_app, :redis)

"OK" = Connex.Redis.flushdb!(pool_name)
nil = Connex.Redis.get!(pool_name, "key")
{:ok, nil} == Connex.Redis.get(pool_name, "key")

"OK" = Connex.Redis.set!(pool_name, "key", "value")
"OK" = Connex.Redis.set!(pool_name, :key, :value)
"value" = Connex.Redis.get!(pool_name, "key")

nil = Connex.Redis.set!(pool_name, "key", "value_nx", [:nx])
"value" = Connex.Redis.get!(pool_name, "key")

# with sharding
shard_name = Application.fetch_env!(:my_app2, :redis_shard)

"OK" == Connex.Redis.shard_set!(shard_name, "shardkey", "key", "value")
"value" == Connex.Redis.shard_get!(shard_name, "shardkey", "key")
```
