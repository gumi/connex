import Config

config :connex, Connex.PoolTest,
  pools: [
    pool1: {[], [key: "value1"]},
    pool2: {[], [key: "value2"]},
    pool3: {[], [key: "value3"]}
  ],
  shards: [shard1: [:pool1, :pool2, :pool3], shard2: [:pool2, :pool3]]

config :connex, Connex.Redis,
  pools: [
    pool1: {[], [host: {:system, "CONNEX_REDIS_HOST"}, database: 0]},
    pool2: {[], [host: {:system, "CONNEX_REDIS_HOST"}, database: 1]},
    pool3: {[], [host: {:system, "CONNEX_REDIS_HOST"}, database: 2]}
  ],
  shards: [shard1: [:pool1, :pool2, :pool3], shard2: [:pool2, :pool3]],
  resolver: Env
