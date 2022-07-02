defmodule Frugal.Encoder do
  @callback encode(any()) :: String.t()
end
