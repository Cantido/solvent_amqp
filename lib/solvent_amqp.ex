defmodule SolventAMQP do
  @moduledoc """
  The `SolventAMQP` library bridges the `Solvent` event bus with an `AMQP` message queue.
  When a message appears on one, it is propagated to the other.

  Events from AMQP are expected to obey the CloudEvents specification for AMQP bindings.
  That way they can be properly translated into a `Solvent.Event`.
  """

  require Logger

  def init(chan, exchange, routing_key) do
    solvent_to_amqp(chan, exchange, routing_key)
    amqp_to_solvent(chan, routing_key)
  end

  def amqp_to_solvent(chan, routing_key) do
    AMQP.Queue.subscribe(chan, routing_key, fn payload, meta ->
      Logger.debug("meta: #{inspect meta, pretty: true}")
      Logger.debug("payload: #{inspect payload, pretty: true}")

      if meta.content_type == "application/cloudevents+json; charset=UTF-8" do
        {:ok, event} = Solvent.Event.from_json(payload)

        if Enum.empty?(:ets.lookup(:solvent_amqp_outgoing, event.id)) do
          Solvent.publish(event)
        else
          true = :ets.delete(:solvent_amqp_outgoing, event.id)
        end
      end
    end)
  end

  def solvent_to_amqp(chan, exchange, routing_key) do
    Solvent.subscribe("Elixir.Solvent.AMQP", :all, fn _type, event_id ->
      if Enum.empty?(:ets.lookup(:solvent_amqp_incoming, event_id)) do
        {:ok, event} = Solvent.EventStore.fetch(event_id)
        true = :ets.insert(:solvent_amqp_outgoing, {event_id})

        # option here for CloudEvents encoding:
        # - binary content mode: event data is in the body of the message, headers are in application properties
        # - structured content mode: entire event is JSON-encoded into event body
        #
        # I'm going to choose binary content with a JSON-encoded body by default.

        payload = Solvent.Event.to_json!(event)

        AMQP.Basic.publish(chan, exchange, routing_key, payload, content_type: "application/cloudevents+json; charset=utf-8")

        Solvent.EventStore.ack(event_id, "Elixir.Solvent.AMQP")
      else
        true = :ets.delete(:solvent_amqp_incoming, event_id)
      end
    end)
  end
end
