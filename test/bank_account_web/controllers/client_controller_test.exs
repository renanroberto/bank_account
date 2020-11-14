defmodule BankAccountWeb.ClientControllerTest do
  use BankAccountWeb.ConnCase

  alias BankAccount.Accounts

  setup do
    client = %{
      name: "Client Test 0",
      cpf: CPF.generate() |> to_string,
      credential: %{
        email: "client0@test.com",
        password: "secret"
      }
    }

    {:ok, created_client} = Accounts.create_client(client)

    {:ok, code} = Accounts.gen_code(created_client)

    %{client: created_client, code: code}
  end

  describe "POST /api/registry" do
    test "registry new client", %{conn: conn} do
      params = %{
        name: "Client Test",
        cpf: CPF.generate() |> to_string(),
        email: "client@test.com",
        password: "secret"
      }

      conn = post(conn, "/api/registry", params)

      assert %{"id" => _, "cpf" => _} = json_response(conn, 201)
    end

    test "update client", %{conn: conn, client: client} do
      params = %{
        name: "Client New Name",
        cpf: client.cpf,
        status_complete: true
      }

      conn = post(conn, "/api/registry", params)

      assert %{
               "id" => _,
               "name" => "Client New Name",
               "status_complete" => false
             } = json_response(conn, 200)
    end

    test "verify client", %{conn: conn, code: code} do
      params = %{
        name: "Client Test",
        cpf: CPF.generate() |> to_string(),
        email: "client@test.com",
        password: "secret",
        birth_date: "1998-01-14",
        gender: "male",
        city: "RJ",
        state: "RJ",
        country: "BR",
        code: code
      }

      conn = post(conn, "/api/registry", params)

      assert %{"status_complete" => true} = json_response(conn, 201)
    end

    test "fail to registry new client: missing CPF", %{conn: conn} do
      params = %{
        name: "Client Test",
        email: "client@test.com",
        password: "secret"
      }

      conn = post(conn, "/api/registry", params)

      assert %{"status" => "error", "error" => "CPF is required"} = json_response(conn, 400)
    end

    test "fail to registry new client: invalid CPF", %{conn: conn} do
      params = %{
        name: "Client Test",
        cpf: "12345",
        email: "client@test.com",
        password: "secret"
      }

      conn = post(conn, "/api/registry", params)

      assert %{"status" => "error", "error" => "invalid CPF"} = json_response(conn, 400)
    end

    test "fail to registry new client: missing email", %{conn: conn} do
      params = %{
        name: "Client Test",
        cpf: CPF.generate() |> to_string(),
        password: "secret"
      }

      conn = post(conn, "/api/registry", params)

      assert %{
               "status" => "error",
               "error" => %{"credential" => _}
             } = json_response(conn, 400)
    end
  end
end
