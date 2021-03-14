defmodule Ueberauth.Strategy.Snowflake.OAuth do
  @moduledoc """
  OAuth2 for Snowflake.
  Add `client_id` and `client_secret` to your configuration:
  config :ueberauth, Ueberauth.Strategy.Snowflake.OAuth,
    client_id: System.get_env("SNOWFLAKE_APP_ID"),
    client_secret: System.get_env("SNOWFLAKE_APP_SECRET")
  """
  use OAuth2.Strategy

  @defaults [
    strategy: __MODULE__,
    token_url: "/oauth/token-request",
    authorize_url: "/oauth/authorize"
  ]

  @doc """
  Construct a client for requests to Snowflake.
  This will be setup automatically for you in `Ueberauth.Strategy.Snowflake`.
  These options are only useful for usage outside the normal callback phase of Ueberauth.
  """
  def client(opts \\ []) do
    config = Application.get_env(:ueberauth, __MODULE__, [])
    opts = @defaults |> Keyword.merge(opts) |> Keyword.merge(config) |> resolve_values()
    json_library = Ueberauth.json_library()

    OAuth2.Client.new(opts)
    |> OAuth2.Client.put_serializer("application/json", json_library)
  end

  @doc """
  Provides the authorize url for the request phase of Ueberauth. No need to call this usually.
  """
  def authorize_url!(params \\ [], opts \\ []) do
    opts
    |> client
    |> OAuth2.Client.authorize_url!(params)
  end

  def get(token, url, headers \\ [], opts \\ []) do
    [token: token]
    |> client
    |> put_param("client_secret", client().client_secret)
    |> OAuth2.Client.get(url, headers, opts)
  end

  def get_access_token(params \\ [], opts \\ []) do
    opts |> client() |> get_token(params)
  end

  def get_access_token_from_refresh_token(params \\ [], opts \\ []) do
    clientx =
      client(opts)
      |> Map.put(:token, %{refresh_token: "x"})
  end

  # Strategy Callbacks

  def authorize_url(xclient, params) do
    OAuth2.Strategy.AuthCode.authorize_url(xclient, params)
  end

  def get_token(xclient, params, headers) do
    xclient
    |> put_param("client_secret", xclient.client_secret)
    |> put_header("Accept", "application/json")
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end

  defp resolve_values(list) do
    for {key, value} <- list do
      {key, resolve_value(value)}
    end
  end

  defp resolve_value({m, f, a}) when is_atom(m) and is_atom(f), do: apply(m, f, a)
  defp resolve_value(v), do: v
end
