defmodule PageConsumer do
  use GenStage

  require Logger

  def start_link(event) do
    Logger.info("PageConsumer received #{event}")
    Task.start_link(fn -> Sender.my_genstage_work() end)
  end

  def init(initial_state) do
    sub_opts = [{PageProducer, min_demand: 0, max_demand: 1}]
    {:consumer, initial_state, subscribe_to: sub_opts}
  end

  def handle_events(events, _from, state) do
    Logger.info("PageConsumer received #{inspect(events)}")
    # Pretending that we're scraping web pages.
    Enum.each(events, fn _page -> Sender.my_genstage_work() end)
    {:noreply, [], state}
  end
end
