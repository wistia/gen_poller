defmodule GenPoller.Stateless do
  @moduledoc """
  A stateless version of `GenPoller`
  """

  @callback handle_tick(state :: map) :: :continue | :pause | {:stop, reason :: term()}

  defdelegate start_link(mod, args), to: GenServer
  defdelegate start_link(mod, args, opts), to: GenServer
  defdelegate start(mod, args), to: GenServer
  defdelegate start(mod, args, opts), to: GenServer

  defmacro __using__(_) do
    quote do
      use GenServer

      @behaviour GenPoller.Stateless

      def init(state) do
        GenPoller.start_loop
        {:ok, state}
      end
      defoverridable [init: 1]

      def handle_info(:do_loop, state) do
        case handle_tick(state[:args]) do
          :continue ->
            GenPoller.start_loop_in(state[:poll_sleep])
            {:noreply, state}

          :pause ->
            {:noreply, state}

          {:stop, reason} ->
            {:stop, reason, state}
        end
      end
    end
  end
end
