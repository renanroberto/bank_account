# Bank Account

*Bank Account* is an Elixir/Phoenix system for opening a bank account with a referral code system.


## Installing and Running

You will need to have installed [Elixir](https://elixir-lang.org/install.html), [Phoenix](https://hexdocs.pm/phoenix/installation.html) and [PostgreSQL](https://www.postgresql.org/download/). Then, follow this steps:

	$ git clone git@github.com:renanroberto/bank_account.git
	$ cd bank_account
	$ mix deps.get
	$ mix ecto.setup
	$ mix phx.server

Now the server should be running on port 4000


## Running the tests

Considering you already cloned this repo

	$ mix test


## Environment variables

This system will be using three environment variables: `SECRET_KEY_BASE`, `SECRET_KEY_GUARDIAN`, and `SECRET_KEY_CLOAK`. You can generate them by:

- `SECRET_KEY_BASE`
calling `$ mix phx.gen.secret`

- `SECRET_KEY_GUARDIAN`
calling `$ mix guardian.gen.secret`

- `SECRET_KEY_CLOAK`
calling on iex `32 |> :crypto.strong_rand_bytes() |> Base.encode64()`



## Creating the first Referral Code

Since no client can complete registration and, therefore, receive a referral code, you will need to generate the first referral code manually.

With the server running, make a request to `/api/admin`. You should receive the code. Keep it safe, you can't generate other code this way.

#### Example:

**request**

`GET http://localhost:4000/api/admin`

**response**

	{
		"code": "56547929"
	}


## Routes available

### /api/registry

Here you can register or update a new client. The expected body is

- name
- cpf*
- email*
- password*
- birth_date
- gender
- city
- state
- country
- code (referral code)

*These fields are required for registration.

CPF is required for both registration and update.

If already exists a user registered with the given CPF, the request will be an update. Note that to perform an update you should be logged in.

#### Example

**request**

`POST http://localhost:4000/api/registry`

**body**

	{
		"name": "Gustavo",
		"cpf": "958.858.190-76",
		"email": "gustavo@example.com",
		"password": "secret"
	}

**response**

	{
		"client": {
			"birth_date": null,
			"city": null,
			"country": null,
			"cpf": "95885819076",
			"email": "gustavo@example.com",
			"gender": null,
			"id": 2,
			"name": "Gustavo",
			"state": null,
			"status_complete": false
		},
		"status": "pending"
	}
	

### /api/login

Here you can log in to your account providing your email and password. If your credentials are correct, you will receive a token. In order to be authenticated in further requests, you will need to pass `Bearer <token>` on `authorization header`.

#### Example

**request**

`POST http://localhost:4000/api/login`

**body**

	{
		"email": "gustavo@example.com",
		"password": "secret"
	}

**response**

	{
		"token": "<token>"
	}


### /api/me

Here you can get information on the current logged in account. If your registration is complete, you can use this route to get your referral code.

#### Example

**request**

`GET http://localhost:4000/api/me`

**headers**

	Authorization: Bearer <token>

**response**

	{
		"client": {
			"birth_date": null,
			"city": null,
			"code": null,
			"country": null,
			"cpf": "95885819076",
			"email": "gustavo@example.com",
			"gender": null,
			"id": 2,
			"name": "Gustavo",
			"state": null,
			"status_complete": false
		},
		"status": "pending"
	}


### /api/indications

Here you can get a list of clients that have been registered with your referral code. This feature is reserved for members with complete registration. Please refer to the section about completing registration for more information.


## Completing registration

To complete your registration, you will need to inform all data mentioned in the registry section. When you complete your registration, the status will be `newly_completed` and the system will give you a congratulation message (yay!) together with your own referral code. Now you can indicate new clients with this code. Just give it to a trusted friend =)

In further requests, your status will be `complete`.

#### Example

**response**

	{
		"client": {
			"birth_date": "1998-01-01",
			"city": "rj",
			"country": "br",
			"cpf": "95885819076",
			"email": "gustavo@example.com",
			"gender": "male",
			"id": 2,
			"name": "Gustavo",
			"state": "rj",
			"status_complete": true
		},
		"code": "66727831",
		"message": "congratulations! You've completed your registration",
		"status": "newly_completed"
	}


## Project decisions

Just like life, software development is made of decisions. But unlike my life, I believe this project enjoys good decisions.

### Guardian

> An authentication library for use with Elixir applications.
> - [Guardian Repository](https://github.com/ueberauth/guardian)

We choose to use Guardian with JSON WEB Token (JWT) to handler authentication in this project. It integrates well with Phoenix and fits well for our simple authentication system. We're using JWT because its use is straightforward for browser, mobile, and any service that can communicate via HTTP with this server.

### Cloak.Ecto

> Easily encrypt fields in your Ecto schemas. Relies on Cloak for encryption.
> - [Ecto Cloak Repository](https://github.com/danielberkompas/cloak_ecto)

We choose to use `Ecto.Cloak` to encrypt `name`, `email`, `cpf` and `birth_date` on database. `Ecto.Cloak` use `Ecto.Types` to encrypt and decrypt automatically your data. After setup, it handles encryption transparently.

### Credential detached from Client

We have separated schemas, `Credential` and `Client`, that share the same context, `Account`. `Credential` is responsible for `email` and `password`, *i.e.*, for fields related to authorization. These fields could be in `Client`, but keeping them apart can facilitate integration with other credential methods in the future (for example, login with google).

### Generating Referral Codes

To generate an 8 digit nonsequential referral code we first check if there is any code available. If so, then we get a random number between 0 and 99999999 and check if it was already generated. If that was the case, we try to generate it again and repeat this process until we get an available code.

This system can generate a total of one hundred million unique codes.


## Difficulties

Since `Ecto.Cloak` change some fields, I'm having trouble to guarantee the uniqueness of them. To work around this, we check for unicity on the client controller. It is not a perfect solution, but I would need more time to make `unique_constraint` from `Ecto` work properly with `Ecto.Cloak`.


## TODOS

* Implement other methods of authentication, like login with Google.
* Delete or deactivate accounts. Already exists methods for deletion on the `Accounts` context module and `Client` already has an `active` field for deactivation.
* Generate referral code asynchronously. For a large number of codes, it can take an indeterminate amount of time to generate the code.
