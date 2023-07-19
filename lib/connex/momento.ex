defmodule Connex.Momento do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init({credential_env_var, default_ttl_seconds}) do
    config = Momento.Configurations.InRegion.Default.latest()
    credential_provider = Momento.Auth.CredentialProvider.from_env_var!(credential_env_var)
    Momento.CacheClient.create(config, credential_provider, default_ttl_seconds)
  end

  @spec get_client(pid :: pid()) :: Momento.CacheClient.t()
  def get_client(pid) do
    GenServer.call(pid, :get_client)
  end

  @spec list_caches(pid :: pid()) :: Momento.Responses.ListCaches.t()
  def list_caches(pid) do
    GenServer.call(pid, :list_caches)
  end

  @spec create_cache(pid :: pid(), cache_name :: String.t()) :: Momento.Responses.ListCaches.t()
  def create_cache(pid, cache_name) do
    GenServer.call(pid, {:create_cache, cache_name})
  end

  @spec set(pid :: pid(), cache_name :: String.t(), key :: binary(), value :: binary()) :: Momento.Responses.Set.t()
  def set(pid, cache_name, key, value) do
    GenServer.call(pid, {:set, cache_name, key, value})
  end

  @spec get(pid :: pid(), cache_name :: String.t(), key :: binary()) :: Momento.Responses.Get.t()
  def get(pid, cache_name, key) do
    GenServer.call(pid, {:get, cache_name, key})
  end

  def handle_call(:get_client, _from, client) do
    {:reply, client, client}
  end

  def handle_call(:list_caches, _from, client) do
    result = Momento.CacheClient.list_caches(client)
    {:reply, result, client}
  end

  def handle_call({:create_cache, cache_name}, _from, client) do
    result = Momento.CacheClient.create_cache(client, cache_name)
    {:reply, result, client}
  end

  def handle_call({:set, cache_name, key, value}, _from, client) do
    result = Momento.CacheClient.set(client, cache_name, key, value)
    {:reply, result, client}
  end

  def handle_call({:get, cache_name, key}, _from, client) do
    result = Momento.CacheClient.get(client, cache_name, key)
    {:reply, result, client}
  end
end
