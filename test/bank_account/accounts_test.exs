defmodule BankAccount.AccountsTest do
  use BankAccount.DataCase

  alias BankAccount.Accounts

  describe "clients" do
    alias BankAccount.Accounts.Client

    @valid_attrs %{active: true, birth_date: ~D[2010-04-17], city: "some city", country: "some country", cpf: "some cpf", gender: "some gender", name: "some name", referral_code: "some referral_code", state: "some state", status_complete: true}
    @update_attrs %{active: false, birth_date: ~D[2011-05-18], city: "some updated city", country: "some updated country", cpf: "some updated cpf", gender: "some updated gender", name: "some updated name", referral_code: "some updated referral_code", state: "some updated state", status_complete: false}
    @invalid_attrs %{active: nil, birth_date: nil, city: nil, country: nil, cpf: nil, gender: nil, name: nil, referral_code: nil, state: nil, status_complete: nil}

    def client_fixture(attrs \\ %{}) do
      {:ok, client} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_client()

      client
    end

    test "list_clients/0 returns all clients" do
      client = client_fixture()
      assert Accounts.list_clients() == [client]
    end

    test "get_client!/1 returns the client with given id" do
      client = client_fixture()
      assert Accounts.get_client!(client.id) == client
    end

    test "create_client/1 with valid data creates a client" do
      assert {:ok, %Client{} = client} = Accounts.create_client(@valid_attrs)
      assert client.active == true
      assert client.birth_date == ~D[2010-04-17]
      assert client.city == "some city"
      assert client.country == "some country"
      assert client.cpf == "some cpf"
      assert client.gender == "some gender"
      assert client.name == "some name"
      assert client.referral_code == "some referral_code"
      assert client.state == "some state"
      assert client.status_complete == true
    end

    test "create_client/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_client(@invalid_attrs)
    end

    test "update_client/2 with valid data updates the client" do
      client = client_fixture()
      assert {:ok, %Client{} = client} = Accounts.update_client(client, @update_attrs)
      assert client.active == false
      assert client.birth_date == ~D[2011-05-18]
      assert client.city == "some updated city"
      assert client.country == "some updated country"
      assert client.cpf == "some updated cpf"
      assert client.gender == "some updated gender"
      assert client.name == "some updated name"
      assert client.referral_code == "some updated referral_code"
      assert client.state == "some updated state"
      assert client.status_complete == false
    end

    test "update_client/2 with invalid data returns error changeset" do
      client = client_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_client(client, @invalid_attrs)
      assert client == Accounts.get_client!(client.id)
    end

    test "delete_client/1 deletes the client" do
      client = client_fixture()
      assert {:ok, %Client{}} = Accounts.delete_client(client)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_client!(client.id) end
    end

    test "change_client/1 returns a client changeset" do
      client = client_fixture()
      assert %Ecto.Changeset{} = Accounts.change_client(client)
    end
  end

  describe "credentials" do
    alias BankAccount.Accounts.Credential

    @valid_attrs %{email: "some email", password: "some password"}
    @update_attrs %{email: "some updated email", password: "some updated password"}
    @invalid_attrs %{email: nil, password: nil}

    def credential_fixture(attrs \\ %{}) do
      {:ok, credential} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_credential()

      credential
    end

    test "list_credentials/0 returns all credentials" do
      credential = credential_fixture()
      assert Accounts.list_credentials() == [credential]
    end

    test "get_credential!/1 returns the credential with given id" do
      credential = credential_fixture()
      assert Accounts.get_credential!(credential.id) == credential
    end

    test "create_credential/1 with valid data creates a credential" do
      assert {:ok, %Credential{} = credential} = Accounts.create_credential(@valid_attrs)
      assert credential.email == "some email"
      assert credential.password == "some password"
    end

    test "create_credential/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_credential(@invalid_attrs)
    end

    test "update_credential/2 with valid data updates the credential" do
      credential = credential_fixture()
      assert {:ok, %Credential{} = credential} = Accounts.update_credential(credential, @update_attrs)
      assert credential.email == "some updated email"
      assert credential.password == "some updated password"
    end

    test "update_credential/2 with invalid data returns error changeset" do
      credential = credential_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_credential(credential, @invalid_attrs)
      assert credential == Accounts.get_credential!(credential.id)
    end

    test "delete_credential/1 deletes the credential" do
      credential = credential_fixture()
      assert {:ok, %Credential{}} = Accounts.delete_credential(credential)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_credential!(credential.id) end
    end

    test "change_credential/1 returns a credential changeset" do
      credential = credential_fixture()
      assert %Ecto.Changeset{} = Accounts.change_credential(credential)
    end
  end
end
