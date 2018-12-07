defmodule SmppexOserl do
  @moduledoc """
  Module for converting [SMPPEX](https://hexdocs.pm/smppex/) Pdu structs
  to format used by [Oserl](https://github.com/iamaleksey/oserl) library.
  """

  def to_oserl(pdu) do
    SmppexOserl.ToOserl.convert(pdu)
  end

  def to_smppex(pdu) do
    SmppexOserl.ToSmppex.convert(pdu)
  end
end
