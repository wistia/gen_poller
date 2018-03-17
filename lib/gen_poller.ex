defmodule GenPoller do
  @moduledoc """
  A behaviour for creating a simple looping `GenServer`. `GenPoller` is backed by the `GenServer`
  module so it offers all of the same callbacks that `GenServer` does. This allows the process to
  respond to interleaved messages while polling. The `poll_sleep` arg must be provided.

    defmodule MyModule do
      use GenPoller

      # Optionally wrap `GenPoller.start_link`
      def start_link do
        GenPoller.start_link(__MODULE__, poll_sleep: 1000)
      end

      # Optionally override `init`
      def init(state) do
        send(self(), :do_loop)
        {:ok, state}
      end

      # The `handle_tick` callback must be implemented
      def handle_tick(state) do
        {:continue, state}
      end
    end

  The `handle_tick/1` callback must be implemented. It should return any of the following tuples:

    * `{:continue, state}` will cause the loop to resume in `state.poll_sleep`
    * `{:pause, state}` will cause the loop to stop until `start_loop` is called again
    * Any tuple that is a valid return value for `handle_info`
  """

  @callback handle_tick(state :: any) :: {:continue, new_state :: any} | {:pause, new_state :: any} | {:stop, reason :: term(), new_state :: any}

  defdelegate start_link(mod, args), to: GenServer
  defdelegate start_link(mod, args, opts), to: GenServer
  defdelegate start(mod, args), to: GenServer
  defdelegate start(mod, args, opts), to: GenServer

  @doc """
  Resumes or starts the poll loop for the current process.
  """
  def start_loop(pid \\ self()) do
    send(pid, :do_loop)
  end

  @doc """
  Like `start_loop` but resumes the poll loop after `ms` milliseconds
  """
  def start_loop_in(pid \\ self(), ms) do
    Process.send_after(pid, :do_loop, ms)
  end

  defmacro __using__(_) do
    quote do
      use GenServer

      @behaviour GenPoller

      def init(state) do
        GenPoller.start_loop
        {:ok, state}
      end
      defoverridable [init: 1]

      def handle_info(:do_loop, state) do
        case handle_tick(state) do
          {:continue, state} ->
            Process.send_after(self(), :do_loop, state[:poll_sleep])
            {:noreply, state}

          {:pause, state} ->
            {:noreply, state}

          res -> res
        end
      end
    end
  end
end
