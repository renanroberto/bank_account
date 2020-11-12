defmodule BankAccount.Vault do
  use Cloak.Vault, otp_app: :bank_account

  @impl GenServer
  def init(config) do
    config =
      Keyword.put(config, :ciphers,
        default: {Cloak.Ciphers.AES.GCM, tag: "AES.GCM.V1", key: decode_env!("SECRET_KEY_CLOAK")}
      )

    {:ok, config}
  end

  defp decode_env!(var) do
    key =
      System.get_env(var) ||
        raise """
        environment variable SECRET_KEY_CLOAK is missing.
        """

    Base.decode64!(key)
  end
end
