defmodule Frugal.Core.EntityTagSet do
  alias Frugal.Core.EntityTag

  @type t :: :any | [EntityTag.t()]

  @spec matches_weak?(t(), EntityTag.t()) :: boolean()
  def matches_weak?(:any, _), do: true

  def matches_weak?(tags, tag) do
    Enum.any?(tags, &EntityTag.weak_eq?(&1, tag))
  end

  @spec matches_strong?(t(), EntityTag.t()) :: boolean()
  def matches_strong?(:any, _), do: true

  def matches_strong?(tags, tag) do
    Enum.any?(tags, &EntityTag.strong_eq?(&1, tag))
  end

  @spec from_string(String.t()) :: t()
  def from_string("*"), do: :any
  def from_string(candidate), do: etag_list(candidate, [])

  defguardp is_etagc(c) when c == 0x21 or (c >= 0x23 and c != 0x7F)

  defguardp is_ws(c) when c in [?\s, ?\t]

  defguardp is_ws_comma(c) when is_ws(c) or c == ?,

  defp etag_list("", acc), do: Enum.reverse(acc)
  defp etag_list(<<h, t::bits>>, acc) when is_ws_comma(h), do: etag_list(t, acc)
  defp etag_list("W/\"" <> t, acc), do: etag(t, acc, :weak, "")
  defp etag_list(<<?", t::bits>>, acc), do: etag(t, acc, :strong, "")

  defp etag(<<?", t::bits>>, acc, type, tag), do: etag_list_sep(t, [{type, tag} | acc])

  defp etag(<<h, t::bits>>, acc, type, tag) when is_etagc(h),
    do: etag(t, acc, type, <<tag::binary, h>>)

  defp etag_list_sep("", acc), do: Enum.reverse(acc)
  defp etag_list_sep(<<h, t::bits>>, acc) when is_ws(h), do: etag_list_sep(t, acc)
  defp etag_list_sep(<<?,, t::bits>>, acc), do: etag_list(t, acc)
end
