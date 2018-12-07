defmodule SmppexOserl.ToOserl do
  alias SMPPEX.Pdu
  alias SMPPEX.Protocol.TlvFormat

  def convert(pdu) do
    {
      Pdu.command_id(pdu),
      Pdu.command_status(pdu),
      Pdu.sequence_number(pdu),
      fields_to_list(pdu)
    }
  end

  defp fields_to_list(pdu) do
    ((pdu |> Pdu.mandatory_fields() |> Map.to_list() |> Enum.map(&string_to_list/1)) ++
       (pdu |> Pdu.optional_fields() |> Map.to_list() |> Enum.map(&ids_to_names/1)))
    |> Enum.map(&preprocess/1)
  end

  defp ids_to_names({name, value}) when is_atom(name) do
    {name, value}
  end

  defp ids_to_names({id, value}) when is_integer(id) do
    case TlvFormat.name_by_id(id) do
      {:ok, name} -> string_to_list({name, value})
      :unknown -> {id, value}
    end
  end

  defp preprocess({:network_error_code, <<type_code::size(8), error_code::size(16)>>}) do
    {:network_error_code, {:network_error_code, type_code, error_code}}
  end

  defp preprocess({:its_session_info, <<session_number::size(8), sequence_number::size(8)>>}) do
    {:its_session_info, {:its_session_info, session_number, sequence_number}}
  end

  defp preprocess({:dest_telematics_id, <<protocol_id::size(8), reserved::size(8)>>}) do
    {:dest_telematics_id, {:telematics_id, protocol_id, reserved}}
  end

  defp preprocess({:source_telematics_id, <<protocol_id::size(8), reserved::size(8)>>}) do
    {:source_telematics_id, {:telematics_id, protocol_id, reserved}}
  end

  defp preprocess({:broadcast_frequency_interval, <<time_unit::size(8), number::size(16)>>}) do
    {:broadcast_frequency_interval, {:broadcast_frequency_interval, time_unit, number}}
  end

  defp preprocess({key, value}) do
    {key, value}
  end

  defp string_to_list({key, value}) when is_binary(value),
    do: {key, :erlang.binary_to_list(value)}

  defp string_to_list({key, value}), do: {key, value}
end
