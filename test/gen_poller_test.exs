defmodule GenPollerTest do
  import TestHelper
  use ExUnit.Case
  doctest GenPoller

  defmodule TestPoller do
    use GenPoller

    def handle_tick(state) do
      send(state.receiver, {:tick, state})
      receive do
        resp -> resp
      end
    end
  end

  defmodule NoStartTestPoller do
    use GenPoller

    def init(state) do
      {:ok, state}
    end

    defdelegate handle_tick(state), to: TestPoller
  end

  defmodule ServerTestPoller do
    use GenPoller

    def handle_call(:ping, _from, state) do
      {:reply, :pong, state}
    end

    def handle_tick(state) do
      {:continue, state}
    end
  end

  test "it works" do
    GenPoller.start_link(TestPoller, %{receiver: self(), poll_sleep: 1})
    assert_receive_tick_then(fn _ -> :ok end)
  end

  test "it keeps ticking" do
    {:ok, pid} = GenPoller.start_link(TestPoller, %{receiver: self(), poll_sleep: 1})
    assert_receive_tick_then(fn state -> send pid, {:continue, state} end)
    assert_receive_tick_then(fn _ -> :ok end)
  end

  test "it can be paused" do
    {:ok, pid} = GenPoller.start_link(TestPoller, %{receiver: self(), poll_sleep: 1})
    assert_receive_tick_then(fn state -> send pid, {:pause, state} end)
    refute_receive_tick()
  end

  test "it can be resumed" do
    {:ok, pid} = GenPoller.start_link(TestPoller, %{receiver: self(), poll_sleep: 1})
    assert_receive_tick_then(fn state -> send pid, {:pause, state} end)
    GenPoller.start_loop(pid)
    assert_receive_tick_then(fn _ -> :ok end)
  end

  test "it can be resumed with a delay" do
    {:ok, pid} = GenPoller.start_link(TestPoller, %{receiver: self(), poll_sleep: 1})
    assert_receive_tick_then(fn state -> send pid, {:pause, state} end)
    GenPoller.start_loop_in(pid, 15)
    refute_receive_tick()
    assert_receive_tick_then(fn _ -> :ok end)
  end

  test "it can be stopped" do
    {:ok, pid} = GenPoller.start_link(TestPoller, %{receiver: self(), poll_sleep: 1})
    assert_receive_tick_then(fn state -> send pid, {:stop, :normal, state} end)
    Process.sleep(10)
    refute Process.alive?(pid)
  end

  test "it can be started with the poll loop off" do
    {:ok, pid} = GenPoller.start_link(NoStartTestPoller, %{receiver: self(), poll_sleep: 1})
    refute_receive_tick()
    GenPoller.start_loop(pid)
    assert_receive_tick_then(fn _ -> :ok end)
  end

  test "it gives us normal GenServer callbacks" do
    {:ok, pid} = GenPoller.start_link(ServerTestPoller, %{poll_sleep: 10})
    assert :pong == GenServer.call(pid, :ping)
  end
end
