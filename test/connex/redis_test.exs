defmodule Connex.RedisTest do
  use ExUnit.Case

  test "run" do
    child_specs = Connex.Redis.child_specs()
    {:ok, pid} = Supervisor.start_link(child_specs, strategy: :one_for_one)

    assert :ok == Connex.Redis.run(:pool1, fn client -> Exredis.Api.set(client, "key", "value1") end)
    assert :ok == Connex.Redis.run(:pool2, fn client -> Exredis.Api.set(client, "key", "value2") end)
    assert :ok == Connex.Redis.run(:pool3, fn client -> Exredis.Api.set(client, "key", "value3") end)
    assert "value1" == Connex.Redis.run(:pool1, fn client -> Exredis.Api.get(client, "key") end)
    assert "value2" == Connex.Redis.run(:pool2, fn client -> Exredis.Api.get(client, "key") end)
    assert "value3" == Connex.Redis.run(:pool3, fn client -> Exredis.Api.get(client, "key") end)

    Supervisor.stop(pid)
  end

  test "shard" do
    child_specs = Connex.Redis.child_specs()
    {:ok, pid} = Supervisor.start_link(child_specs, strategy: :one_for_one)

    assert :ok == Connex.Redis.shard(:shard1, "test1", fn client -> Exredis.Api.set(client, "key", "value1") end)
    assert :ok == Connex.Redis.shard(:shard1, "test2", fn client -> Exredis.Api.set(client, "key", "value2") end)
    assert :ok == Connex.Redis.shard(:shard1, "test8", fn client -> Exredis.Api.set(client, "key", "value3") end)

    assert "value1" == Connex.Redis.shard(:shard1, "test1", fn client -> Exredis.Api.get(client, "key") end)
    assert "value2" == Connex.Redis.shard(:shard1, "test2", fn client -> Exredis.Api.get(client, "key") end)
    assert "value3" == Connex.Redis.shard(:shard1, "test8", fn client -> Exredis.Api.get(client, "key") end)

    assert :ok == Connex.Redis.shard(:shard2, "test1", fn client -> Exredis.Api.set(client, "key", "value3") end)
    assert :ok == Connex.Redis.shard(:shard2, "test5", fn client -> Exredis.Api.set(client, "key", "value2") end)

    assert "value3" == Connex.Redis.shard(:shard2, "test1", fn client -> Exredis.Api.get(client, "key") end)
    assert "value2" == Connex.Redis.shard(:shard2, "test5", fn client -> Exredis.Api.get(client, "key") end)

    Supervisor.stop(pid)
  end

  test "apis" do
    child_specs = Connex.Redis.child_specs()
    {:ok, pid} = Supervisor.start_link(child_specs, strategy: :one_for_one)

    assert :ok == Connex.Redis.set(:pool1, "key", "value1")
    assert :ok == Connex.Redis.set(:pool2, "key", "value2")
    assert :ok == Connex.Redis.set(:pool3, "key", "value3")
    assert "value1" == Connex.Redis.get(:pool1, "key")
    assert "value2" == Connex.Redis.get(:pool2, "key")
    assert "value3" == Connex.Redis.get(:pool3, "key")

    Supervisor.stop(pid)
  end
end
