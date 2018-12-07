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
         {5156, "any tlv field"},
         {:esm_class, []}
       ]}

    pdu = SmppexOserl.to_smppex(oserl_pdu)

    assert 1 == Pdu.command_id(pdu)
    assert 2 == Pdu.command_status(pdu)
    assert 3 == Pdu.sequence_number(pdu)
    assert "message" == Pdu.mandatory_field(pdu, :short_message)
    assert "message payload" == Pdu.optional_field(pdu, :message_payload)
    assert "any tlv field" == Pdu.optional_field(pdu, 0x1424)
    assert <<1, 0, 2>> == Pdu.optional_field(pdu, :network_error_code)
    assert <<1, 2>> == Pdu.field(pdu, :its_session_info)
    assert nil == Pdu.field(pdu, :esm_class)
  end

  test "from smppex to oserl" do
    pdu =
      Pdu.new({1, 2, 3}, %{short_message: "message"}, %{
        0x0424 => "message payload",
        0x1424 => "any tlv field"
      })

    assert {1, 2, 3, fields} = SmppexOserl.to_oserl(pdu)

    assert [
             {5156, "any tlv field"},
             {:message_payload, 'message payload'},
             {:short_message, 'message'}
           ] == Enum.sort(fields)
  end
end
