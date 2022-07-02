defmodule FrugalTest do
  use Frugal.ConnCase, async: true

  alias Frugal.ConditionalRequest

  describe "validators/1" do
    test "returns validators", %{conn: conn} do
      refute ConditionalRequest.validators(conn)

      validators = [etag: "asd"]
      conn = ConditionalRequest.put_validators(conn, validators)

      assert ^validators = ConditionalRequest.validators(conn)
    end
  end

  describe "put_validators/2" do
    test "sets validators on connection", %{conn: conn} do
      conn = ConditionalRequest.put_validators(conn, etag: "asd")

      assert ConditionalRequest.validators(conn)
    end
  end
end
