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
    (pdu |> Pdu.mandatory_fields() |> Map.to_list() |> Enum.map(&string_to_list(&1))) ++
      (pdu |> Pdu.optional_fields() |> Map.to_list() |> ids_to_names)
  end

  defp ids_to_names(by_ids, by_names \\ [])

  defp ids_to_names([], by_names), do: by_names

  defp ids_to_names([{name, value} | by_ids], by_names) when is_atom(name),
    do: ids_to_names(by_ids, [{name, value} | by_names])

  defp ids_to_names([{id, value} | by_ids], by_names) when is_integer(id) do
    case TlvFormat.name_by_id(id) do
      {:ok, name} -> ids_to_names(by_ids, [string_to_list({name, value}) | by_names])
      :unknown -> ids_to_names(by_ids, [{id, value} | by_names])
    end
  end

  defp string_to_list({key, value}) when is_binary(value),
    do: {key, :erlang.binary_to_list(value)}

  defp string_to_list({key, value}), do: {key, value}
end
