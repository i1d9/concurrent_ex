defmodule Sender.Periodical do
  use GenServer

  require Logger

  def start_link(start_from, opts \\ []) do
    GenServer.start_link(__MODULE__, start_from, opts)
  end

  def init(initial_state) do
    Logger.info("Successfully started scheduled background daemon")
    my_scheduler()
    {:ok, initial_state}
  end

  def handle_info(:work, current_state) do
    new_state = current_state |> Map.put(:counter, current_state.counter + 1)
    my_scheduler()
    Logger.info("Updated State")
    IO.inspect(new_state)
    {:noreply, new_state}
  end

  defp my_scheduler do
    Process.send_after(self(), :work, 5_000)
  end
end
