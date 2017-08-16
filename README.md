# GenPoller

a simple, generic behaviour for doing stuff on some interval

## Usage

```ex
defmodule Heartbeat do
  use GenPoller

  def start_link(opts \\ [])
    GenPoller.start_link(__MODULE__, %{poll_sleep: @poll_sleep, call_count: 0, is_retry: false}, opts)
  end

  # GenPoller will give you a default init/1 callback which calls GenPoller.start_loop
  # If you need to override this callback you may want to make sure that you start the loop
  # if you want it to start automatically

  # handle_tick/1 must be implemented and should return anything handle_info/2
  # expects or one of `{:continue, state}` or `{:pause, state}`
  def handle_tick(state) do
    case hit_url do
      :ok ->
        state = update_in(state[:call_count], &(&1 + 1))
        state = put_in(state[:is_retry], false)
        {:continue, state}

      {:error, :host_down} ->
        if state.is_retry do
          # The host was down; lets give it 10s to come back up and retry
          GenPoller.start_loop_in(10_000)
          state = put_in(state[:is_retry], true)
          {:pause, state}
        else
          # The host was down and failed on the retry; crash the process
          {:stop, :host_down, state}
        end
    end
  end

  # GenPoller is built on top of GenServer so you can implement calls/casts
  # just like you would with GenServer
  def handle_call(:call_count, _, state = %{call_count: call_count}) do
    {:reply, call_count, state}
  end
end
```
