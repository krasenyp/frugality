defmodule Frugal.Core.Metadata do
  alias Frugal.Core.EntityTag

  @type t :: %__MODULE__{
          entity_tag: EntityTag.t(),
          last_modified: DateTime.t()
        }

  @type header_pair :: {String.t(), String.t()}

  defstruct [:entity_tag, :last_modified]

  @spec new(Enum.t()) :: t()
  def new(fields) do
    struct!(__MODULE__, fields)
  end

  @spec to_headers(t()) :: [header_pair()]
  def to_headers(%__MODULE__{entity_tag: nil, last_modified: nil}), do: []

  def to_headers(%__MODULE__{entity_tag: etag, last_modified: nil}),
    do: [{"etag", EntityTag.to_string(etag)}]

  def to_headers(%__MODULE__{entity_tag: nil, last_modified: lm}),
    do: [{"last-modified", serialize_date(lm)}]

  def to_headers(%__MODULE__{entity_tag: etag, last_modified: lm}),
    do: [{"etag", EntityTag.to_string(etag)}, {"last-modified", serialize_date(lm)}]

  defp serialize_date(%DateTime{} = dt) do
    dt
    |> DateTime.to_naive()
    |> NaiveDateTime.to_erl()
    |> :cow_date.rfc1123()
  end
end
