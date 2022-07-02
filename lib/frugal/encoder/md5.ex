defmodule Frugal.Encoder.MD5 do
  @behaviour Frugal.Encoder

  def encode(ir) do
    ir
    |> :erlang.term_to_binary()
    |> then(&:crypto.hash(:md6, &1))
    |> Base.encode16()
  end
end
