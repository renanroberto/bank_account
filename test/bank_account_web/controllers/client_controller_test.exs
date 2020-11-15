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

  describe "GET /api/me" do
    test "success to get me", %{conn: conn, client: client} do
      conn = BankAccount.Accounts.Guardian.Plug.sign_in(conn, client)
      conn = get(conn, "api/me")

      assert %{
               "status" => "pending",
               "client" => %{
                 "id" => _,
                 "code" => _
               }
             } = json_response(conn, 200)
    end

    test "fail to get me", %{conn: conn} do
      conn = get(conn, "/api/me")
      assert %{"error" => "unauthenticated"} = json_response(conn, 401)
    end
  end

  describe "GET /api/indications" do
    test "success to get indications", %{conn: conn, code: code} do
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

      conn_create = post(conn, "/api/registry", params)

      assert %{
               "status" => "newly_completed",
               "message" => _,
               "code" => new_code,
               "client" => %{
                 "id" => id,
                 "status_complete" => true
               }
             } = json_response(conn_create, 201)

      params_2 = %{
        params
        | cpf: CPF.generate() |> to_string(),
          email: "client2@test.com",
          code: new_code
      }

      params_3 = %{
        params
        | cpf: CPF.generate() |> to_string(),
          email: "client3@test.com",
          code: new_code
      }

      post(conn, "api/registry", params_2)
      post(conn, "api/registry", params_3)

      conn =
        conn
        |> BankAccount.Accounts.Guardian.Plug.sign_in(%{id: id})
        |> get("/api/indications")

      clients =
        conn
        |> json_response(200)
        |> Enum.map(&Map.get(&1, "client"))

      assert length(clients) == 2
      assert [%{"id" => _}, %{"id" => _}] = clients
    end

    test "fail to get indications: account not complete", %{conn: conn, client: client} do
      assert client.status_complete == false

      conn =
        conn
        |> BankAccount.Accounts.Guardian.Plug.sign_in(%{id: client.id})
        |> get("/api/indications")

      assert %{
               "error" => "feature reserved for members with complete registry"
             } = json_response(conn, 401)
    end

    test "fail to get indications: not logged in", %{conn: conn} do
      conn = get(conn, "/api/me")
      assert %{"error" => "unauthenticated"} = json_response(conn, 401)
    end
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

      assert %{
               "status" => "pending",
               "client" => %{"id" => _, "cpf" => _}
             } = json_response(conn, 201)
    end

    test "update client", %{conn: conn, client: client} do
      conn = BankAccount.Accounts.Guardian.Plug.sign_in(conn, client)

      params = %{
        name: "Client New Name",
        cpf: client.cpf,
        status_complete: true
      }

      conn = post(conn, "/api/registry", params)

      assert %{
               "status" => "pending",
               "client" => %{
                 "id" => _,
                 "name" => "Client New Name",
                 "status_complete" => false
               }
             } = json_response(conn, 200)
    end

    test "verify new client", %{conn: conn, code: code} do
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

      conn_create = post(conn, "/api/registry", params)

      assert %{
               "status" => "newly_completed",
               "message" => _,
               "code" => code,
               "client" => %{
                 "id" => id,
                 "status_complete" => true
               }
             } = json_response(conn_create, 201)

      assert {:ok, %Accounts.Referral{}} = Accounts.get_referral(code)

      conn =
        conn
        |> BankAccount.Accounts.Guardian.Plug.sign_in(%{id: id})
        |> get("/api/me")

      assert %{
               "status" => "complete",
               "client" => %{"code" => code}
             } = json_response(conn, 200)

      assert String.valid?(code)
    end

    test "verify updated client", %{conn: conn, code: code} do
      params = %{
        name: "Client Test",
        cpf: CPF.generate() |> to_string(),
        email: "client@test.com",
        password: "secret",
        birth_date: "1998-01-14",
        gender: "male",
        city: "RJ",
        state: "RJ",
        country: "BR"
      }

      conn_create = post(conn, "/api/registry", params)

      assert %{
               "status" => "pending",
               "client" => %{
                 "id" => id,
                 "cpf" => cpf,
                 "status_complete" => false
               }
             } = json_response(conn_create, 201)

      client = %{id: id}
      conn = BankAccount.Accounts.Guardian.Plug.sign_in(conn, client)

      conn_update = post(conn, "/api/registry", %{cpf: cpf, code: code})

      assert %{
               "status" => "newly_completed",
               "message" => _,
               "code" => code,
               "client" => %{
                 "id" => _,
                 "status_complete" => true
               }
             } = json_response(conn_update, 200)

      assert {:ok, %Accounts.Referral{}} = Accounts.get_referral(code)

      conn_update_2 =
        conn
        |> BankAccount.Accounts.Guardian.Plug.sign_in(%{id: id})
        |> get("/api/me")

      assert %{
               "status" => "complete",
               "client" => %{"code" => code}
             } = json_response(conn_update_2, 200)

      assert String.valid?(code)
    end

    test "fail to register new client: missing CPF", %{conn: conn} do
      params = %{
        name: "Client Test",
        email: "client@test.com",
        password: "secret"
      }

      conn = post(conn, "/api/registry", params)

      assert %{"status" => "error", "error" => "CPF is required"} = json_response(conn, 400)
    end

    test "fail to register new client: invalid CPF", %{conn: conn} do
      params = %{
        name: "Client Test",
        cpf: "12345",
        email: "client@test.com",
        password: "secret"
      }

      conn = post(conn, "/api/registry", params)

      assert %{"status" => "error", "error" => "invalid CPF"} = json_response(conn, 400)
    end

    test "fail to register new client: email already used", %{conn: conn, client: client} do
      params = %{
        name: "Client Test",
        cpf: CPF.generate() |> to_string(),
        email: client.credential.email,
        password: "secret"
      }

      conn = post(conn, "/api/registry", params)

      assert %{"status" => "error", "error" => "email already in use"} = json_response(conn, 400)
    end

    test "fail to register new client: missing email", %{conn: conn} do
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
