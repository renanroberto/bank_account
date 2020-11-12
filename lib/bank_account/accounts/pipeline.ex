defmodule BankAccount.Accounts.Pipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :bank_account,
    error_handler: BankAccountWeb.ErrorHandlerController,
    module: BankAccount.Accounts.Guardian

  plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}
  plug Guardian.Plug.LoadResource, allow_blank: true
end
