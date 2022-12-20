defmodule Sender.Stack do
  use GenServer

  require Logger

  def start_link(start_from, opts \\ []) do
    GenServer.start_link(__MODULE__, start_from, opts)
  end

  @impl true
  def init(initial_state) do
    Logger.info("Genserver started")
    {:ok, initial_state}
  end

  @impl true
  def handle_call(:pop, _from, [head | tail]) do
    {:reply, head, tail}
  end

  @impl true
  def handle_cast({:push, element}, state) do
    {:noreply, [element | state]}
  end
end
