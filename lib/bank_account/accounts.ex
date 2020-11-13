defmodule BankAccount.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias BankAccount.Repo

  alias BankAccount.Accounts.Client
  alias BankAccount.Accounts.Credential

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

  defp verify_client(%Client{} = client) do
    # TODO generate code properly
    code = "12345678"

    attrs = %{
      status_complete: true,
      referral_code: code
    }

    with {:ok, verified_client} <-
           client
           |> Client.changeset(attrs)
           |> Ecto.Changeset.cast_assoc(
             :credential,
             with: &Credential.changeset/2
           )
           |> Repo.update() do
      {:ok, Repo.preload(verified_client, :credential)}
    end
  end

  defp check_status(%Client{} = client) do
    validations = [
      not is_nil(client.name),
      not is_nil(client.credential.email),
      not is_nil(client.cpf),
      not is_nil(client.birth_date),
      not is_nil(client.gender),
      not is_nil(client.city),
      not is_nil(client.state),
      not is_nil(client.country),
      not is_nil(client.refered)
    ]

    if Enum.all?(validations), do: :complete, else: :pending
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
    query = from c in Credential, where: c.email == ^email

    case Repo.one(query) do
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
end
