# GenPoller

a simple, generic behaviour for doing stuff on some interval

## Usage

```ex
defmodule Heartbeat do
  use GenPoller

  def start_link(opts \\ []) do
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

## GenPoller.Stateless

Sometimes there's less mental overhead knowing a poller is stateless.
For those cases you can use `GenPoller.Stateless` instead which does not allow
the tick loop to modify the poller's state.

Note that `GenPoller.Stateless` is still a `GenServer` under the hood which means it still confomrs to OTP message passing
(e.g. it responds correctly to `:sys.get_state`) and it can still implement normal stateful `handle_{call,cast}`
handlers while simultaneously supporting a stateless daemon loop.
