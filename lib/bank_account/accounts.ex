defmodule BankAccount.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias BankAccount.Repo

  alias BankAccount.Accounts.Client
  alias BankAccount.Accounts.Credential
  alias BankAccount.Accounts.Referral

  @doc """
  Returns the list of clients.

  ## Examples

      iex> list_clients()
      [%Client{}, ...]

  """
  def list_clients do
    Client
    |> Repo.all()
    |> Repo.preload(:credential)
  end

  @doc """
  Gets a single client.

  Raises `Ecto.NoResultsError` if the Client does not exist.

  ## Examples

      iex> get_client!(123)
      %Client{}

      iex> get_client!(456)
      ** (Ecto.NoResultsError)

  """
  def get_client!(id) do
    Client
    |> Repo.get!(id)
    |> Repo.preload(:credential)
  end

  def get_client_by_cpf(cpf) do
    cpf = cpf |> CPF.parse!() |> to_string
    result = Repo.get_by(Client, cpf_hash: cpf)

    case result do
      nil ->
        {:error, :client_not_found}

      client ->
        {:ok, client}
    end
  end

  @doc """
  Creates a client.

  ## Examples

      iex> create_client(%{field: value})
      {:ok, %Client{}}

      iex> create_client(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_client(attrs \\ %{}) do
    with {:ok, client} <-
           %Client{}
           |> Client.changeset(attrs)
           |> Ecto.Changeset.cast_assoc(
             :credential,
             with: &Credential.changeset/2
           )
           |> Repo.insert() do
      case check_status(client) do
        :pending ->
          {:ok, Repo.preload(client, :credential)}

        :complete ->
          verify_client(client)
      end
    end
  end

  @doc """
  Updates a client.

  ## Examples

      iex> update_client(client, %{field: new_value})
      {:ok, %Client{}}

      iex> update_client(client, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_client(%Client{} = client, attrs) do
    with {:ok, updated_client} <-
           client
           |> Client.changeset(attrs)
           |> Ecto.Changeset.cast_assoc(
             :credential,
             with: &Credential.changeset/2
           )
           |> Repo.update() do
      updated_client = Repo.preload(updated_client, :credential)

      case check_status(updated_client) do
        :pending ->
          {:ok, updated_client}

        :complete ->
          verify_client(updated_client)
      end
    end
  end

  @doc """
  Deletes a client.

  ## Examples

      iex> delete_client(client)
      {:ok, %Client{}}

      iex> delete_client(client)
      {:error, %Ecto.Changeset{}}

  """
  def delete_client(%Client{} = client) do
    Repo.delete(client)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking client changes.

  ## Examples

      iex> change_client(client)
      %Ecto.Changeset{data: %Client{}}

  """
  def change_client(%Client{} = client, attrs \\ %{}) do
    Client.changeset(client, attrs)
  end

  @doc """
  Returns the list of credentials.

  ## Examples

      iex> list_credentials()
      [%Credential{}, ...]

  """
  def list_credentials do
    Repo.all(Credential)
  end

  @doc """
  Gets a single credential.

  Raises `Ecto.NoResultsError` if the Credential does not exist.

  ## Examples

      iex> get_credential!(123)
      %Credential{}

      iex> get_credential!(456)
      ** (Ecto.NoResultsError)

  """
  def get_credential!(id), do: Repo.get!(Credential, id)

  def get_credential_by_email(email) when is_binary(email) do
    result = Repo.get_by(Credential, email_hash: email)

    case result do
      nil ->
        {:error, :credential_not_found}

      client ->
        {:ok, client}
    end
  end

  def get_credential_by_email(_), do: {:error, :credential_not_found}

  @doc """
  Creates a credential.

  ## Examples

      iex> create_credential(%{field: value})
      {:ok, %Credential{}}

      iex> create_credential(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_credential(attrs \\ %{}) do
    %Credential{}
    |> Credential.changeset(attrs)
    |> Repo.insert()
  end

  def authenticate_credential(email, plain_password) do
    result = Repo.get_by(Credential, email_hash: email)

    case result do
      nil ->
        Argon2.no_user_verify()
        {:error, :invalid_credentials}

      credential ->
        if Argon2.verify_pass(plain_password, credential.password) do
          {:ok, credential}
        else
          {:error, :invalid_credentials}
        end
    end
  end

  @doc """
  Updates a credential.

  ## Examples

      iex> update_credential(credential, %{field: new_value})
      {:ok, %Credential{}}

      iex> update_credential(credential, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_credential(%Credential{} = credential, attrs) do
    credential
    |> Credential.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a credential.

  ## Examples

      iex> delete_credential(credential)
      {:ok, %Credential{}}

      iex> delete_credential(credential)
      {:error, %Ecto.Changeset{}}

  """
  def delete_credential(%Credential{} = credential) do
    Repo.delete(credential)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking credential changes.

  ## Examples

      iex> change_credential(credential)
      %Ecto.Changeset{data: %Credential{}}

  """
  def change_credential(%Credential{} = credential, attrs \\ %{}) do
    Credential.changeset(credential, attrs)
  end

  @required_fields [
    :name,
    :cpf,
    :email,
    :birth_date,
    :gender,
    :city,
    :state,
    :country,
    :refered_id
  ]

  defp check_status(%Client{} = client) do
    email = client |> Map.get(:credential, %{}) |> Map.get(:email)
    client = Map.put(client, :email, email)

    validated =
      not Enum.any?(
        @required_fields,
        &is_nil(Map.get(client, &1))
      )

    if validated, do: :complete, else: :pending
  end

  defp verify_client(%Client{status_complete: false} = client) do
    attrs = %{
      status_complete: true
    }

    with {:ok, verified_client} <-
           client
           |> Client.private_changeset(attrs)
           |> Ecto.Changeset.cast_assoc(
             :credential,
             with: &Credential.changeset/2
           )
           |> Repo.update(),
         {:ok, code} <- gen_code(verified_client) do
      verified_client =
        verified_client
        |> Repo.preload(:credential)
        |> Map.put(:code, code)

      {:ok, verified_client}
    end
  end

  defp verify_client(client), do: {:ok, client}

  def gen_code(%Client{} = client) do
    limit = 100_000_000

    case full?(limit) do
      {:ok, :codes_available} ->
        code = :rand.uniform(limit) - 1

        query =
          from r in Referral,
            where: r.code == ^code

        if Repo.exists?(query) do
          gen_code(client)
        else
          with {:ok, referral} <- insert_referral(client, code),
               do: {:ok, num_to_code(referral.code)}
        end

      error ->
        error
    end
  end

  def get_indicated(%Client{status_complete: true} = client) do
    referral_query = from r in Referral, where: r.client_id == ^client.id
    referral = Repo.one(referral_query)

    clients_query = from c in Client, where: c.refered_id == ^referral.id

    Repo.all(clients_query)
  end

  def get_referral(code) do
    {code, _} = Integer.parse(code)

    query =
      from r in Referral,
        where: r.code == ^code

    if referral = Repo.one(query) do
      {:ok, referral}
    else
      {:error, :referral_not_found}
    end
  end

  def get_code(%Client{} = client) do
    query =
      from r in Referral,
        where: r.client_id == ^client.id

    if referral = Repo.one(query) do
      {:ok, num_to_code(referral.code)}
    else
      {:error, :code_not_found}
    end
  end

  defp num_to_code(num) do
    num
    |> Integer.to_string()
    |> String.pad_leading(8, "0")
  end

  defp insert_referral(client, code) do
    %Referral{}
    |> Referral.changeset(%{code: code, client_id: client.id})
    |> Repo.insert()
  end

  defp full?(limit) do
    query = from r in Referral, select: count()

    if Repo.one(query) < limit do
      {:ok, :codes_available}
    else
      {:error, :codes_sold_out}
    end
  end
end
