{:ok, pid} = Connex.Momento.start_link({"MOMENTO_AUTH_TOKEN", 3600})

IO.inspect(Connex.Momento.list_caches(pid))

IO.inspect(Connex.Momento.create_cache(pid, "cache"))

IO.inspect(Connex.Momento.set(pid, "cache", "key", "value"))

IO.inspect(Connex.Momento.get(pid, "cache", "key"))
