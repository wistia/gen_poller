defmodule GenPoller.Stateless do
  @moduledoc """
  A stateless version of `GenPoller`
  """

  use GenPoller

  @callback init(state :: map) :: GenServer.init
  @callback handle_tick(state :: map) :: :continue | :pause | {:stop, reason :: term()}

  def start_link(mod, state, opts \\ []) do
    state = put_in(state[:mod], mod)
    GenPoller.start_link(__MODULE__, state, opts)
  end

  def start(mod, state, opts \\ []) do
    state = put_in(state[:mod], mod)
    GenPoller.start(__MODULE__, state, opts)
  end

  def init(state) do
    state.mod.init(state)
  end

  def handle_tick(state) do
    case state.mod.handle_tick(state.args) do
      :continue -> {:continue, state}
      :pause -> {:pause, state}
      {:stop, reason} -> {:stop, reason, state}
    end
  end

  defmacro __using__(_) do
    quote do
      @behaviour GenPoller.Stateless

      def init(state) do
        GenPoller.start_loop
        {:ok, state}
      end
      defoverridable [init: 1]
    end
  end
end
