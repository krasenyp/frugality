defmodule Frugal.Core.EntityTag do
  @type weak :: {:weak, String.t()}
  @type strong :: {:strong, String.t()}
  @type t :: weak() | strong()

  @spec weak(String.t()) :: weak()
  defmacro weak(tag) do
    quote do
      {:weak, unquote(tag)}
    end
  end

  @spec strong(String.t()) :: strong()
  defmacro strong(tag) do
    quote do
      {:strong, unquote(tag)}
    end
  end

  @spec to_string(t()) :: String.t()
  def to_string(weak(tag)), do: "W/\"#{tag}\""

  def to_string(strong(tag)), do: "\"#{tag}\""

  @spec weak_eq?(t(), t()) :: boolean()
  def weak_eq?({_, tag}, {_, tag}), do: true

  def weak_eq?(_, _), do: false

  @spec weak_ne?(t(), t()) :: boolean()
  def weak_ne?(eta, etb), do: not weak_eq?(eta, etb)

  @spec strong_eq?(t(), t()) :: boolean()
  def strong_eq?(strong(tag), strong(tag)), do: true

  def strong_eq?(_, _), do: false

  @spec strong_ne?(t(), t()) :: boolean()
  def strong_ne?(eta, etb), do: not strong_eq?(eta, etb)
end
