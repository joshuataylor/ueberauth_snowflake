# Überauth Snowflake

> Snowflake strategy for Überauth.

Install the latest version of Überauth Snowflake from [https://hex.pm/packages/ueberauth_snowflake](https://hex.pm/packages/ueberauth_snowflake)

Documentation is available at [http://hexdocs.pm/ueberauth_snowflake](http://hexdocs.pm/ueberauth_snowflake)

Source code is available at [https://github.com/joshuataylor/ueberauth_snowflake](https://github.com/joshuataylor/ueberauth_snowflake)

## Installation

1. Have a valid, working Snowflake account that has `accountadmin` access.

2. Have a read of https://docs.snowflake.com/en/user-guide/oauth-custom.html to understand how OAuth works with Snowflake.

3. Add a new security integration:
```sql
create or replace security integration oauth_myname
  type = oauth
  OAUTH_ALLOW_NON_TLS_REDIRECT_URI = true -- for testing, once this is removed, remove this
  enabled = true
  oauth_client = custom
  oauth_client_type = 'CONFIDENTIAL'
  oauth_redirect_uri = 'http://localhost:4000/auth/snowflake/callback'
  oauth_issue_refresh_tokens = true
  oauth_refresh_token_validity = 86400 -- in seconds. This can be set to like 7776000 for 90 days.
;
```

Once you have added the security integration, to get the client_id and secret key, run:
```sql
select system$show_oauth_client_secrets('OAUTH_MYNAME');
```

This will return:
```json
{"OAUTH_CLIENT_SECRET_2":"xxx","OAUTH_CLIENT_SECRET":"xxx","OAUTH_CLIENT_ID":"xxx"}
```

Note the OAUTH_CLIENT_SECRET and the OAUTH_CLIENT_ID.

4. Add `:ueberauth_snowflake` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ueberauth_snowflake, "~> 0.1"}]
    end
    ```

5. Add the strategy to your applications:

    ```elixir
    def application do
      [applications: [:ueberauth_snowflake]]
    end
    ```

6. Add Snowflake to your Überauth configuration:

    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        snowflake: {Ueberauth.Strategy.Snowflake, []}
      ]
    ```

7. Update your provider configuration:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.Snowflake.OAuth,
      client_id: System.get_env("SNOWFLAKE_CLIENT_ID"),
      client_secret: System.get_env("SNOWFLAKE_CLIENT_SECRET")
    ```

8. Include the Überauth plug in your controller:

    ```elixir
    defmodule MyApp.AuthController do
      use MyApp.Web, :controller

      plug Ueberauth
    end
    ```

9. Create the request and callback routes if you haven't already:

    ```elixir
    scope "/auth", MyApp do
      pipe_through :browser

      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
    ```

10. Your controller needs to implement callbacks to deal with `Ueberauth.Auth` and `Ueberauth.Failure` responses.

For an example implementation see the [Überauth Example](https://github.com/ueberauth/ueberauth_example) application.

## Calling

Depending on the configured url you can initiate the request through:

    /auth/snowflake

Or with options:

    /auth/snowflake?perms=delete

By default the permissions are the ones defined in your application
authentication flow on Snowflake. To override them, set a `perms` query value on
the request path or in your configuration. Allowed values are "read", "write",
or "delete".

```elixir
config :ueberauth, Ueberauth,
  providers: [
    snowflake: {Ueberauth.Strategy.Snowflake, [default_perms: "delete"]}
  ]
```

## License

Please see [LICENSE](https://github.com/joshuataylor/ueberauth_snowflake/blob/master/LICENSE) for licensing details.
