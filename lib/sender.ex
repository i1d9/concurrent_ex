defmodule Sender do
  @moduledoc """
  Documentation for `Sender`.
  """

  alias Sender.{JobRunner, Job}

  def send_email("konnichiwa@world.com" = email), do: :error

  def send_email(email) do
    Process.sleep(3000)
    IO.puts("Email to #{email} sent")
    {:ok, "email_sent"}
  end

  def notify_all(emails) do
    Sender.EmailTaskSupervisor
    |> Task.Supervisor.async_stream_nolink(emails, &send_email/1)
    |> Enum.to_list()
  end

  def start_job(args) do
    DynamicSupervisor.start_child(JobRunner, {Job, args})
  end

  def my_genstage_work() do
    5..10
    |> Enum.random()
    |> :timer.seconds()
    |> Process.sleep()
  end
end
