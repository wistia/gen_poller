defmodule TestHelper do
  defmacro assert_receive_tick_then(fun, timeout \\ 10) do
    quote do
      receive do
        {:tick, state} -> unquote(fun).(state)
      after
        unquote(timeout) -> flunk()
      end
    end
  end

  defmacro refute_receive_tick(timeout \\ 10) do
    quote do
      receive do
        _ -> flunk()
      after
        unquote(timeout) -> :ok
      end
    end
  end
end

ExUnit.start()
