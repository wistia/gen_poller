defmodule GenPoller.StatelessTest do
  import TestHelper
  use ExUnit.Case, async: true

  defmodule TestPoller do
    use GenPoller.Stateless

    def handle_tick(args = [receiver]) do
      send(receiver, {:tick, args})
      receive do
        resp -> resp
      end
    end
  end

  defmodule NoStartTestPoller do
    use GenPoller.Stateless

    def init(state) do
      {:ok, state}
    end

    defdelegate handle_tick(args), to: TestPoller
  end

  defmodule ServerTestPoller do
    use GenPoller.Stateless

    def handle_call(:ping, _from, state) do
      {:reply, :pong, state}
    end

    def handle_tick(_args) do
      :continue
    end
  end

  test "it passes the original args to the tick function" do
    GenPoller.Stateless.start_link(TestPoller, %{args: [self()], poll_sleep: 1})
    assert_receive_tick_then(fn args ->
      assert args == [self()]
    end)
  end

  test "it works" do
    GenPoller.Stateless.start_link(TestPoller, %{args: [self()], poll_sleep: 1})
    assert_receive_tick_then(fn _ -> :ok end)
  end

  test "it keeps ticking" do
    {:ok, pid} = GenPoller.Stateless.start_link(TestPoller, %{args: [self()], poll_sleep: 1})
    assert_receive_tick_then(fn _ -> send pid, :continue end)
    assert_receive_tick_then(fn _ -> :ok end)
  end

  test "it can be paused" do
    {:ok, pid} = GenPoller.Stateless.start_link(TestPoller, %{args: [self()], poll_sleep: 1})
    assert_receive_tick_then(fn _ -> send pid, :pause end)
    refute_receive_tick()
  end

  test "it can be resumed" do
    {:ok, pid} = GenPoller.Stateless.start_link(TestPoller, %{args: [self()], poll_sleep: 1})
    assert_receive_tick_then(fn _ -> send pid, :pause end)
    GenPoller.start_loop(pid)
    assert_receive_tick_then(fn _ -> :ok end)
  end

  test "it can be resumed with a delay" do
    {:ok, pid} = GenPoller.Stateless.start_link(TestPoller, %{args: [self()], poll_sleep: 1})
    assert_receive_tick_then(fn _ -> send pid, :pause end)
    GenPoller.start_loop_in(pid, 15)
    refute_receive_tick()
    assert_receive_tick_then(fn _ -> :ok end)
  end

  test "it can be stopped" do
    {:ok, pid} = GenPoller.Stateless.start_link(TestPoller, %{args: [self()], poll_sleep: 1})
    assert_receive_tick_then(fn _ -> send pid, {:stop, :normal} end)
    Process.sleep(10)
    refute Process.alive?(pid)
  end

  test "it can be started with the poll loop off" do
    {:ok, pid} = GenPoller.Stateless.start_link(NoStartTestPoller, %{args: [self()], poll_sleep: 1})
    refute_receive_tick()
    GenPoller.start_loop(pid)
    assert_receive_tick_then(fn _ -> :ok end)
  end

  test "it gives us normal GenServer callbacks" do
    {:ok, pid} = GenPoller.Stateless.start_link(ServerTestPoller, %{poll_sleep: 10})
    assert :pong == GenServer.call(pid, :ping)
  end
end
