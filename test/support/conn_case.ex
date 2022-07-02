defmodule Frugal.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Plug.Conn
      import Frugal.ConnCase
    end
  end

  setup _tags do
    {:ok, conn: build_conn()}
  end

  defp build_conn() do
    build_conn(:get, "/", nil)
  end

  def build_conn(method, path, params_or_body \\ nil) do
    Plug.Adapters.Test.Conn.conn(%Plug.Conn{}, method, path, params_or_body)
  end
end
