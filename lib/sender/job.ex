defmodule Sender.Job do
  use GenServer

  require Logger

  defstruct [:work, :id, :max_retries, retries: 0, status: "new"]

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(initial_state) do
    work = Keyword.fetch!(initial_state, :work)
    id = Keyword.get(initial_state, :id, random_job_id())
    max_retries = Keyword.get(initial_state, :max_retries, 3)
    state = %Sender.Job{id: id, work: work, max_retries: max_retries}
    {:ok, state, {:continue, :run}}
  end

  def handle_continue(:run, state) do
    new_state = state.work.() |> handle_job_result(state)

    if new_state.state == "errored" do
      Process.send_after(self(), :retry, 5000)
      {:noreply, new_state}
    else
      Logger.info("Job exiting #{state.id}")
      {:stop, :normal, new_state}
    end
  end

  def handle_info(:retry, state) do
    # Delegate work to the `handle_continue/2` callback.
    {:noreply, state, {:continue, :run}}
  end

  defp random_job_id() do
    :crypto.strong_rand_bytes(5) |> Base.url_encode64(padding: false)
  end

  defp handle_job_result({:ok, _data}, state) do
    Logger.info("Job completed #{state.id}")
    %Sender.Job{state | status: "done"}
  end

  defp handle_job_result(:error, %{status: "new"} = state) do
    Logger.warn("Job errored #{state.id}")
    %Sender.Job{state | status: "errored"}
  end

  defp handle_job_result(:error, %{status: "errored"} = state) do
    Logger.warn("Job retry failed #{state.id}")
    new_state = %Sender.Job{state | retries: state.retries + 1}

    if new_state.retries == state.max_retries do
      %Sender.Job{new_state | status: "failed"}
    else
      new_state
    end
  end
end
