defmodule Frugal do
  alias Frugal.Core.Condition
  alias Frugal.Core.Conditions
  alias Frugal.Core.EntityTagSet
  alias Frugal.Core.Metadata

  @type header_pair :: {String.t(), [String.t()]}

  @spec derive_validators(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def derive_validators(%Plug.Conn{private: %{frugal_validator: validator}} = conn, assigns) do
    assigns =
      assigns
      |> Enum.into(%{})
      |> Map.put(:conn, conn)

    validators = validator.derive(assigns)

    put_validators(conn, validators)
  end

  @spec put_validators(Plug.Conn.t(), Metadata.t()) :: Plug.Conn.t()
  def put_validators(%Plug.Conn{} = conn, validators) do
    conn
    |> Plug.Conn.put_private(:frugal_validators, validators)
    |> Plug.Conn.register_before_send(&apply_validators/1)
  end

  @spec validators(Plug.Conn.t()) :: Metadata.t()
  def validators(%Plug.Conn{private: %{frugal_validators: validators}}), do: validators

  def validators(%Plug.Conn{}), do: Metadata.new(entity_tag: nil, last_modified: nil)

  @spec apply_validators(Plug.Conn.t()) :: Plug.Conn.t()
  def apply_validators(%Plug.Conn{private: %{frugal_validators: validators}} = conn) do
    Plug.Conn.merge_resp_headers(conn, Metadata.to_headers(validators))
  end

  @spec short_circuit(Plug.Conn.t(), (fun(Plug.Conn.t()) -> Plug.Conn.t())) :: Plug.Conn.t()
  def short_circuit(%Plug.Conn{} = conn, cont) when is_function(cont, 1) do
    validators = validators(conn)

    evaluation_result =
      conn
      |> conditions()
      |> Conditions.evaluate(validators)

    case evaluation_result do
      :ok ->
        cont.(conn)

      :not_modified ->
        Plug.Conn.send_resp(conn, 304, "")

      :precondition_failed ->
        Plug.Conn.send_resp(conn, 422, "")
    end
  end

  def conditions(%Plug.Conn{method: method} = conn) do
    # `if-modified-since` is evaluated only when the method is GET or HEAD so it
    # can be skipped otherwise.
    if_modified_since =
      if method in ["GET", "HEAD"] do
        ["if-modified-since"]
      else
        []
      end

    conditions_stream =
      [
        "if-match",
        "if-unmodified-since",
        "if-none-match"
        | if_modified_since
      ]
      |> Stream.map(&get_req_header(conn, &1))
      |> Stream.transform([], &filter_by_precedence/2)
      |> Stream.map(&into_req_condition/1)

    Conditions.new(method: method, conditions: conditions_stream)
  end

  defp get_req_header(%Plug.Conn{} = conn, header) do
    {header, Plug.Conn.get_req_header(conn, header)}
  end

  defp filter_by_precedence({_, []}, acc), do: {[], acc}

  defp filter_by_precedence({"if-unmodified-since", _}, [_ | _] = acc), do: {[], acc}

  defp filter_by_precedence({"if-modified-since", _}, [{"if-none-match", _} | _] = acc),
    do: {[], acc}

  defp filter_by_precedence(header, acc), do: {[header], [header | acc]}

  defp into_req_condition({"if-match", values}) do
    values
    |> Enum.join(", ")
    |> EntityTagSet.from_string()
    |> Condition.if_match()
  end

  defp into_req_condition({"if-none-match", values}) do
    values
    |> Enum.join(", ")
    |> EntityTagSet.from_string()
    |> Condition.if_none_match()
  end

  defp into_req_condition({"if-modified-since", [value | _]}) do
    value
    |> :cow_date.parse_date()
    |> NaiveDateTime.from_erl!()
    |> DateTime.from_naive!("Etc/UTC")
    |> Condition.if_modified_since()
  end

  defp into_req_condition({"if-unmodified-since", [value | _]}) do
    value
    |> :cow_date.parse_date()
    |> NaiveDateTime.from_erl!()
    |> DateTime.from_naive!("Etc/UTC")
    |> Condition.if_unmodified_since()
  end
end
