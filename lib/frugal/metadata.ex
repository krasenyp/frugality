defmodule Frugal.Metadata do
  @behaviour Plug

  @type input :: map()
  @type entity_tag :: any() | nil
  @type last_modified :: DateTime.t() | nil

  @callback entity_tag(input()) :: entity_tag()
  @callback last_modified(input()) :: last_modified()

  alias Frugal.Core.Metadata

  defmacro __using__(opts \\ []) do
    encoder = Keyword.get(opts, :encoder, Frugal.Encoder.MD5)

    quote do
      @behaviour Frugal.Metadata

      @impl Frugal.Metadata
      def entity_tag(_), do: nil

      @impl Frugal.Metadata
      def last_modified(_), do: nil

      defoverridable Frugal.Metadata

      @spec derive(any()) :: Frugal.Core.Metadata.t()
      def derive(data) do
        Frugal.Metadata.derive(__MODULE__, unquote(encoder), data)
      end
    end
  end

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(%Plug.Conn{} = conn, opts) do
    via = Keyword.get(opts, :via)

    Plug.Conn.put_private(conn, :frugal_validator, via)
  end

  @spec derive(module(), module(), input()) :: Metadata.t()
  def derive(validator, encoder, %{} = data) do
    entity_tag =
      data
      |> validator.entity_tag()
      |> encoder.encode()

    %Metadata{
      entity_tag: {:weak, entity_tag},
      last_modified: validator.last_modified(data)
    }
  end

  def derive(validator, data), do: derive(validator, Enum.into(data, %{}))
end
