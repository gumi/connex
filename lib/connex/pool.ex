defmodule Connex.Pool do
  def make_real_pool_name(config_name, pool_name) do
    Module.concat(config_name, pool_name)
  end

  def child_spec(config_name, pool_name, override_pool_args) do
    config = Application.fetch_env!(:connex, config_name)
    pools = Keyword.fetch!(config, :pools)
    {pool_args, worker_args} = Keyword.fetch!(pools, pool_name)

    pool_name = make_real_pool_name(config_name, pool_name)
    pool_args = Keyword.merge([name: {:local, pool_name}], pool_args)
    pool_args = Keyword.merge(pool_args, override_pool_args)
    pool_args = resolve(pool_args, config_name)

    :poolboy.child_spec(pool_name, pool_args, worker_args)
  end

  def child_specs(config_name, override_pool_args) do
    config = Application.fetch_env!(:connex, config_name)
    pools = Keyword.fetch!(config, :pools)

    for {pool_name, _} <- pools do
      child_spec(config_name, pool_name, override_pool_args)
    end
  end

  def run(config_name, pool_name, fun) when is_atom(pool_name) do
    :poolboy.transaction(make_real_pool_name(config_name, pool_name), fun)
  end

  def run(config_name, {shard_name, shard_key}, fun) when is_atom(shard_name) do
    config = Application.fetch_env!(:connex, config_name)
    shards = Keyword.fetch!(config, :shards)
    shard = Keyword.fetch!(shards, shard_name)
    n = :erlang.phash2(shard_key, length(shard))
    pool_name = Enum.at(shard, n)
    run(config_name, pool_name, fun)
  end

  def resolve(value, config_name) do
    config = Application.fetch_env!(:connex, config_name)

    case Keyword.fetch(config, :resolver) do
      {:ok, resolver} when resolver == Env ->
        resolver.resolve(value, :connex, [:unused], fn _, value -> value end)

      {:ok, resolver} ->
        resolver.resolve(value)

      :error ->
        value
    end
  end
end
