defmodule SmppexOserlTest do
  use ExUnit.Case
  doctest SmppexOserl

  alias SMPPEX.Pdu

  test "from osert to smppex" do
    oserl_pdu =
      {1, 2, 3,
       [
         {:message_payload, 'message payload'},
         {:short_message, 'message'},
         {:network_error_code, {:network_error_code, 1, 2}},
         {:its_session_info, {:its_session_info, 1, 2}},
         {:dest_telematics_id, {:telematics_id, 6, 7}},
         {:source_telematics_id, {:telematics_id, 8, 9}},
         {5156, "any tlv field"}
       ]}

    pdu = SmppexOserl.to_smppex(oserl_pdu)

    assert 1 == Pdu.command_id(pdu)
    assert 2 == Pdu.command_status(pdu)
    assert 3 == Pdu.sequence_number(pdu)

    assert "message" == Pdu.field(pdu, :short_message)
    assert "message payload" == Pdu.field(pdu, :message_payload)
    assert "any tlv field" == Pdu.field(pdu, 0x1424)
    assert <<1, 0, 2>> == Pdu.field(pdu, :network_error_code)
    assert <<1, 2>> == Pdu.field(pdu, :its_session_info)
    assert <<6, 7>> == Pdu.field(pdu, :dest_telematics_id)
    assert <<8, 9>> == Pdu.field(pdu, :source_telematics_id)
  end

  test "empty network_error_code" do
    assert nil ==
             {1, 2, 3, [{:network_error_code, []}]}
             |> SmppexOserl.to_smppex()
             |> Pdu.field(:network_error_code)
  end

  test "from smppex to oserl" do
    pdu =
      Pdu.new({1, 2, 3}, %{short_message: "message"}, %{})
      |> Pdu.set_optional_field(0x1424, "any tlv field")
      |> Pdu.set_optional_field(:message_payload, "message payload")
      |> Pdu.set_optional_field(:network_error_code, <<1, 0, 3>>)
      |> Pdu.set_optional_field(:its_session_info, <<1, 2>>)
      |> Pdu.set_optional_field(:dest_telematics_id, <<6, 7>>)
      |> Pdu.set_optional_field(:source_telematics_id, <<8, 9>>)

    assert {1, 2, 3, fields} = SmppexOserl.to_oserl(pdu)

    assert Enum.sort([
             {5156, "any tlv field"},
             {:its_session_info, {:its_session_info, 1, 2}},
             {:message_payload, 'message payload'},
             {:network_error_code, {:network_error_code, 1, 3}},
             {:short_message, 'message'},
             {:dest_telematics_id, {:telematics_id, 6, 7}},
             {:source_telematics_id, {:telematics_id, 8, 9}},
           ]) == Enum.sort(fields)
  end

  test "optional fields by id" do
    pdu =
      Pdu.new({1, 2, 3}, %{short_message: "message"}, %{
        0x0008 => <<6, 7>>,
        0x0010 => <<8, 9>>,
        0x0423 => <<1, 0, 3>>,
        0x0424 => "message payload",
        0x1383 => <<1, 2>>,
        0x1424 => "any tlv field"
      })

    assert {1, 2, 3, fields} = SmppexOserl.to_oserl(pdu)

    assert Enum.sort([
             {5156, "any tlv field"},
             {:its_session_info, {:its_session_info, 1, 2}},
             {:message_payload, 'message payload'},
             {:network_error_code, {:network_error_code, 1, 3}},
             {:short_message, 'message'},
             {:dest_telematics_id, {:telematics_id, 6, 7}},
             {:source_telematics_id, {:telematics_id, 8, 9}},
           ]) == Enum.sort(fields)
  end

  test "utf characters in short_message" do
    pdu = {1, 2, 3, [{:short_message, [1080]}]}
    assert_raise(ArgumentError, fn -> SmppexOserl.to_smppex(pdu) end)
  end
end
