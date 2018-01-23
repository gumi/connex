defmodule Connex.PoolTest do
  use ExUnit.Case

  defmodule Mock do
    use GenServer

    def init(args) do
      {:ok, args}
    end

    def start_link(args) do
      GenServer.start_link(__MODULE__, args)
    end

    def handle_call(:get_key, _from, args) do
      {:reply, Keyword.fetch!(args, :key), args}
    end
  end

  test "run" do
    child_specs = Connex.Pool.child_specs(Connex.PoolTest, worker_module: Connex.PoolTest.Mock)
    {:ok, pid} = Supervisor.start_link(child_specs, strategy: :one_for_one)

    call = &GenServer.call(&1, :get_key)
    assert "value1" == Connex.Pool.run(Connex.PoolTest, :pool1, call)
    assert "value2" == Connex.Pool.run(Connex.PoolTest, :pool2, call)
    assert "value3" == Connex.Pool.run(Connex.PoolTest, :pool3, call)

    Supervisor.stop(pid)
  end

  test "shard" do
    child_specs = Connex.Pool.child_specs(Connex.PoolTest, worker_module: Connex.PoolTest.Mock)
    {:ok, pid} = Supervisor.start_link(child_specs, strategy: :one_for_one)

    call = &GenServer.call(&1, :get_key)
    assert "value1" == Connex.Pool.run(Connex.PoolTest, {:shard1, "test1"}, call)
    assert "value2" == Connex.Pool.run(Connex.PoolTest, {:shard1, "test2"}, call)
    assert "value3" == Connex.Pool.run(Connex.PoolTest, {:shard1, "test8"}, call)
    assert "value3" == Connex.Pool.run(Connex.PoolTest, {:shard2, "test1"}, call)
    assert "value2" == Connex.Pool.run(Connex.PoolTest, {:shard2, "test5"}, call)

    Supervisor.stop(pid)
  end
end
