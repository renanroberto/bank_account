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
      case check_status(updated_client) do
        :pending ->
          {:ok, Repo.preload(updated_client, :credential)}

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

  defp check_status(%Client{} = client) do
    validations = [
      not is_nil(client.name),
      not is_nil(client |> Map.get(:credential, %{}) |> Map.get(:email)),
      not is_nil(client.cpf),
      not is_nil(client.birth_date),
      not is_nil(client.gender),
      not is_nil(client.city),
      not is_nil(client.state),
      not is_nil(client.country),
      not is_nil(client.refered_id)
    ]

    if Enum.all?(validations), do: :complete, else: :pending
  end

  defp verify_client(%Client{} = client) do
    attrs = %{
      status_complete: true
    }

    with {:ok, verified_client} <-
           client
           |> Client.changeset(attrs)
           |> Ecto.Changeset.cast_assoc(
             :credential,
             with: &Credential.changeset/2
           )
           |> Repo.update(),
         {:ok, _code} <- gen_code(verified_client) do
      {:ok, Repo.preload(verified_client, :credential)}
    end
  end

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
