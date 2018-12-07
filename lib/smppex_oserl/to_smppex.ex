defmodule SmppexOserl.ToSmppex do
  alias SMPPEX.Pdu
  alias SMPPEX.Protocol.TlvFormat

  require Record
  Record.defrecord(:network_error_code, type: 0, error: 0)
  Record.defrecord(:its_session_info, session_number: 0, sequence_number: 0)

  def convert({command_id, command_status, sequence_number, field_list} = _oserl_pdu) do
    converted_field_list =
      field_list
      |> Enum.map(&preprocess/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.map(&list_to_string/1)

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

  defp list_to_string({key, value}) when is_list(value), do: {key, :erlang.list_to_binary(value)}
  defp list_to_string({key, value}), do: {key, value}

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

  defp preprocess({key, value}) do
    {key, value}
  end
end
