defmodule GenPollerTest do
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

  test "it works" do
    GenPoller.start_link(TestPoller, %{receiver: self(), poll_sleep: 1})

    receive do
      {:tick, _state} -> :ok
    after
      10 -> flunk()
    end
  end

  test "it keeps ticking" do
    {:ok, pid} = GenPoller.start_link(TestPoller, %{receiver: self(), poll_sleep: 1})

    receive do
      {:tick, state} -> send pid, {:continue, state}
    after
      10 -> flunk()
    end

    receive do
      {:tick, state} -> send pid, {:continue, state}
    after
      10 -> flunk()
    end
  end

  test "it can be paused" do
    {:ok, pid} = GenPoller.start_link(TestPoller, %{receiver: self(), poll_sleep: 1})

    receive do
      {:tick, state} -> send pid, {:pause, state}
    after
      10 -> flunk()
    end

    receive do
      _ -> flunk()
    after
      10 -> :ok
    end
  end

  test "it can be resumed" do
    {:ok, pid} = GenPoller.start_link(TestPoller, %{receiver: self(), poll_sleep: 1})

    receive do
      {:tick, state} -> send pid, {:pause, state}
    after
      10 -> flunk()
    end

    GenPoller.start_loop(pid)

    receive do
      {:tick, _state} -> :ok
    after
      10 -> flunk()
    end
  end

  test "it can be resumed with a delay" do
    {:ok, pid} = GenPoller.start_link(TestPoller, %{receiver: self(), poll_sleep: 1})

    receive do
      {:tick, state} -> send pid, {:pause, state}
    after
      10 -> flunk()
    end

    GenPoller.start_loop_in(pid, 15)

    receive do
      _ -> flunk()
    after
      10 -> :ok
    end

    receive do
      {:tick, _state} -> :ok
    after
      10 -> flunk()
    end
  end
end
