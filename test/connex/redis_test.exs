defmodule Connex.RedisTest do
  use ExUnit.Case

  test "run" do
    child_specs = Connex.Redis.child_specs()
    {:ok, pid} = Supervisor.start_link(child_specs, strategy: :one_for_one)

    run = fn command -> &Redix.command!(&1, command) end
    assert "OK" == Connex.Redis.run(:pool1, run.(["SET", "key", "value1"]))
    assert "OK" == Connex.Redis.run(:pool2, run.(["SET", "key", "value2"]))
    assert "OK" == Connex.Redis.run(:pool3, run.(["SET", "key", "value3"]))
    assert "value1" == Connex.Redis.run(:pool1, run.(["GET", "key"]))
    assert "value2" == Connex.Redis.run(:pool2, run.(["GET", "key"]))
    assert "value3" == Connex.Redis.run(:pool3, run.(["GET", "key"]))

    Supervisor.stop(pid)
  end

  test "shard" do
    child_specs = Connex.Redis.child_specs()
    {:ok, pid} = Supervisor.start_link(child_specs, strategy: :one_for_one)

    run = fn command -> &Redix.command!(&1, command) end
    assert "OK" == Connex.Redis.run({:shard1, "test1"}, run.(["SET", "key", "value1"]))
    assert "OK" == Connex.Redis.run({:shard1, "test2"}, run.(["SET", "key", "value2"]))
    assert "OK" == Connex.Redis.run({:shard1, "test8"}, run.(["SET", "key", "value3"]))

    assert "value1" == Connex.Redis.run({:shard1, "test1"}, run.(["GET", "key"]))
    assert "value2" == Connex.Redis.run({:shard1, "test2"}, run.(["GET", "key"]))
    assert "value3" == Connex.Redis.run({:shard1, "test8"}, run.(["GET", "key"]))

    assert "OK" == Connex.Redis.run({:shard2, "test1"}, run.(["SET", "key", "value3"]))
    assert "OK" == Connex.Redis.run({:shard2, "test5"}, run.(["SET", "key", "value2"]))

    assert "value3" == Connex.Redis.run({:shard2, "test1"}, run.(["GET", "key"]))
    assert "value2" == Connex.Redis.run({:shard2, "test5"}, run.(["GET", "key"]))

    Supervisor.stop(pid)
  end

  test "apis" do
    child_specs = Connex.Redis.child_specs()
    {:ok, pid} = Supervisor.start_link(child_specs, strategy: :one_for_one)

    assert "OK" == Connex.Redis.flushdb!(:pool1)

    assert nil == Connex.Redis.get!(:pool1, "key")
    assert {:ok, nil} == Connex.Redis.get(:pool1, "key")

    assert "OK" == Connex.Redis.set!(:pool1, :key, :value, [:ex, 10])

    assert nil == Connex.Redis.set!(:pool1, :key, :value_nx, [:nx])
    assert "value" == Connex.Redis.get!(:pool1, "key")

    assert "OK" == Connex.Redis.set!(:pool1, "key", "value1")
    assert "OK" == Connex.Redis.set!(:pool2, "key", "value2")
    assert "OK" == Connex.Redis.set!(:pool3, "key", "value3")
    assert "value1" == Connex.Redis.get!(:pool1, "key")
    assert "value2" == Connex.Redis.get!(:pool2, "key")
    assert "value3" == Connex.Redis.get!(:pool3, "key")

    assert {:ok, "value3"} == Connex.Redis.get(:pool3, "key")

    # shards
    assert "OK" == Connex.Redis.set!({:shard1, "test1"}, "key", "value1")
    assert "OK" == Connex.Redis.set!({:shard1, "test2"}, "key", "value2")
    assert "OK" == Connex.Redis.set!({:shard1, "test8"}, "key", "value3")

    assert "value1" == Connex.Redis.get!({:shard1, "test1"}, "key")
    assert "value2" == Connex.Redis.get!({:shard1, "test2"}, "key")
    assert "value3" == Connex.Redis.get!({:shard1, "test8"}, "key")

    assert "OK" == Connex.Redis.set!({:shard2, "test1"}, "key", "value3")
    assert "OK" == Connex.Redis.set!({:shard2, "test5"}, "key", "value2")

    assert "value3" == Connex.Redis.get!({:shard2, "test1"}, "key")
    assert "value2" == Connex.Redis.get!({:shard2, "test5"}, "key")

    Supervisor.stop(pid)
  end

  test "string apis" do
    child_specs = Connex.Redis.child_specs()
    {:ok, pid} = Supervisor.start_link(child_specs, strategy: :one_for_one)

    assert "OK" == Connex.Redis.flushdb!(:pool1)

    assert "OK" == Connex.Redis.set!(:pool1, "test", "10")
    assert 11 == Connex.Redis.incr!(:pool1, "test")
    assert 10 == Connex.Redis.decr!(:pool1, "test")
    assert 12 == Connex.Redis.incrby!(:pool1, "test", 2)
    assert 10 == Connex.Redis.decrby!(:pool1, "test", 2)
    assert "10.5" == Connex.Redis.incrbyfloat!(:pool1, "test", 0.5)
    assert "10" == Connex.Redis.incrbyfloat!(:pool1, "test", -0.5)
    assert "10" == Connex.Redis.getset!(:pool1, "test", 100)
    assert 7 == Connex.Redis.append!(:pool1, "test", "fooo")
    assert "00fo" == Connex.Redis.getrange!(:pool1, "test", 1, 4)
    assert 7 == Connex.Redis.strlen!(:pool1, "test")

    Supervisor.stop(pid)
  end

  test "transactions" do
    child_specs = Connex.Redis.child_specs()
    {:ok, pid} = Supervisor.start_link(child_specs, strategy: :one_for_one)

    assert "OK" == Connex.Redis.flushdb!(:pool1)

    Connex.Redis.run(:pool1, fn client ->
      assert "OK" == Connex.Redis.multi!(client)
      assert "QUEUED" == Connex.Redis.set!(client, "key", "value")
      assert "QUEUED" == Connex.Redis.set!(client, "key", "value2")
      assert "QUEUED" == Connex.Redis.get!(client, "key")
      assert ["OK", "OK", "value2"] == Connex.Redis.exec!(client)
    end)

    Supervisor.stop(pid)
  end
end
