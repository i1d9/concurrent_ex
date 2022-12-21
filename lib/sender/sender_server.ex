defmodule Sender.SenderServer do
  use GenServer

  def init(initial_state) do
    # Initate retries
    Process.send_after(self(), :retry, 5000)

    IO.puts("Received arguments: #{inspect(initial_state)}")
    max_retries = Keyword.get(initial_state, :max_retries, 5)
    state = %{emails: [], max_retries: max_retries}
    {:ok, state}
  end

  def handle_info(:retry, state) do
    {failed, done} =
      Enum.split_with(state.emails, fn email ->
        email.status == "failed" && email.retries < state.max_retries
      end)

    retried =
      failed
      |> Enum.map(fn failor ->
        IO.puts("Retrying email #{failor.email}...")

        new_status =
          case Sender.send_email(failor.email) do
            {:ok, "email_sent"} -> "sent"
            :error -> "failed"
          end

        %{email: failor.email, status: new_status, retries: failor.retries + 1}
      end)

    Process.send_after(self(), :retry, 5000)
    {:noreply, Map.put(state, :emails, retried ++ done)}
  end

  def handle_call(:get_state, _from, state) do
    new_state = state
    {:reply, state, new_state}
  end

  def handle_cast({:send, email}, state) do
    status =
      case Sender.send_email(email) do
        {:ok, "email_sent"} -> "sent"
        :error -> "failed"
      end

    emails = [%{email: email, status: status, retries: 0}] ++ state.emails

    new_state =
      state
      |> Map.update!(:emails, fn _existing_value -> emails end)

    {:noreply, new_state}
  end
end
