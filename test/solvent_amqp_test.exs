defmodule SolventAMQPTest do
  use ExUnit.Case
  doctest SolventAMQP
  alias Solvent.Event

  setup do
    {:ok, connection} = AMQP.Connection.open("amqp://guest:guest@localhost:5672")
    {:ok, channel} = AMQP.Channel.open(connection)

    queue = Base.encode16(:crypto.strong_rand_bytes(8))

    AMQP.Queue.declare(channel, queue)

    %{
      connection: connection,
      channel: channel,
      queue: queue
    }
  end


  test "messages go from Solvent to Rabbit", %{channel: chan, queue: queue} do
    test_pid = self()
    test_ref = make_ref()

    AMQP.Queue.subscribe(chan, queue, fn _payload, _meta ->
      send test_pid, test_ref
    end)

    SolventAMQP.solvent_to_amqp(chan, "", queue)
    Solvent.publish("com.example.solvent_to_rabbit.published")

    assert_receive ^test_ref
  end

  test "messages go from Rabbit to Solvent", %{channel: chan, queue: queue} do
    test_pid = self()
    test_ref = make_ref()

    Solvent.subscribe("com.example.rabbit_to_solvent.published", fn _, _ ->
      send test_pid, test_ref
    end)


    SolventAMQP.amqp_to_solvent(chan, queue)

    serialized_event =
      Event.new("com.example.rabbit_to_solvent.published")
      |> Event.to_json!()

    AMQP.Basic.publish(chan, "", queue, serialized_event, content_type: "application/cloudevents+json; charset=UTF-8")

    assert_receive ^test_ref
  end
end
