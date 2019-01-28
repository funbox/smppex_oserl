defmodule SmppexOserl.ToSmppex do
  alias SMPPEX.Pdu
  alias SMPPEX.Protocol.TlvFormat

  require Record
  Record.defrecord(:network_error_code, type: 0, error: 0)
  Record.defrecord(:its_session_info, session_number: 0, sequence_number: 0)
  Record.defrecord(:telematics_id, protocol_id: 0, reserved: 0)
  Record.defrecord(:broadcast_frequency_interval, time_unit: 0, number: 0)

  def convert({command_id, command_status, sequence_number, field_list} = _oserl_pdu) do
    converted_field_list =
      field_list
      |> Enum.map(fn field ->
        try do
          preprocess(field)
        rescue
          error ->
            raise ArgumentError, "Error #{inspect(error)} converting field #{inspect(field)}"
        end
      end)
      |> Enum.reject(&is_nil/1)

    {mandatory, optional} = list_to_fields(converted_field_list, %{}, %{})

    Pdu.new(
      {command_id, command_status, sequence_number},
      mandatory,
      optional
    )
  end

  defp list_to_fields([], mandatory, optional), do: {mandatory, optional}

  defp list_to_fields([{name, value} | list], mandatory, optional) do
    case kind(name) do
      {:optional, id} -> list_to_fields(list, mandatory, Map.put(optional, id, value))
      :mandatory -> list_to_fields(list, Map.put(mandatory, name, value), optional)
    end
  end

  defp kind(id) when is_integer(id), do: {:optional, id}

  defp kind(name) when is_atom(name) do
    case TlvFormat.id_by_name(name) do
      {:ok, id} -> {:optional, id}
      :unknown -> :mandatory
    end
  end

  defp preprocess({:network_error_code, network_error_code(type: type_code, error: error_code)}) do
    {:network_error_code, <<type_code::size(8), error_code::size(16)>>}
  end

  defp preprocess({:network_error_code, []}) do
    nil
  end

  defp preprocess(
         {:its_session_info,
          its_session_info(session_number: session_number, sequence_number: sequence_number)}
       ) do
    {:its_session_info, <<session_number::size(8), sequence_number::size(8)>>}
  end

  defp preprocess({key, telematics_id(protocol_id: protocol_id, reserved: reserved)})
       when key == :dest_telematics_id or key == :source_telematics_id do
    {key, <<protocol_id::size(8), reserved::size(8)>>}
  end

  defp preprocess(
         {:broadcast_frequency_interval,
          broadcast_frequency_interval(time_unit: time_unit, number: number)}
       ) do
    {:broadcast_frequency_interval, <<time_unit::size(8), number::size(16)>>}
  end

  defp preprocess({key, value}) when is_list(value) do
    {key, :erlang.list_to_binary(value)}
  end

  defp preprocess({key, value}) do
    {key, value}
  end
end
