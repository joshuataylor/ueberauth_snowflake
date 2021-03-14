defmodule Ueberauth.Strategy.Snowflake do
  use Ueberauth.Strategy,
    uid_field: :sub,
    default_scope: "refresh_token session:role:ANALYST"

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra

  @doc """
  Handles initial request for Snowflake authentication.
  """
  def handle_request!(conn) do
    scopes = conn.params["scope"] || option(conn, :default_scope)

    params =
      [scope: scopes]
      |> with_optional(:prompt, conn)
      |> with_optional(:access_type, conn)
      |> with_optional(:include_granted_scopes, conn)
      |> with_param(:access_type, conn)
      |> with_param(:state, conn)

    opts = oauth_client_options_from_conn(conn)
    redirect!(conn, Ueberauth.Strategy.Snowflake.OAuth.authorize_url!(params, opts))
  end

  @doc """
  Handles the callback from Snowflake.
  """
  def handle_callback!(%Plug.Conn{params: %{"code" => code} = p2} = conn) do
    params = [code: code]
    opts = oauth_client_options_from_conn(conn)

    case Ueberauth.Strategy.Snowflake.OAuth.get_access_token(params, opts) do
      {:ok, token} ->
        fetch_user(conn, token)

      {:error, {error_code, error_description}} ->
        set_errors!(conn, [error(error_code, error_description)])
    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc false
  def handle_cleanup!(conn) do
    conn
#    |> put_private(:snowflake_user, nil)
#    |> put_private(:snowflake_login, nil)
  end

  @doc """
  Fetches the uid field from the response.
  """
  def uid(conn) do
    uid_field =
      conn
      |> option(:uid_field)
      |> to_string

    conn.private.snowflake_user[uid_field]
  end

  @doc """
  Includes the credentials from the snowflake response.
  """
  def credentials(conn) do
    token = conn.private.snowflake_oauth
    scope_string = token.other_params["scope"] || ""
    scopes = String.split(scope_string, ",")

    %Credentials{
      expires: !!token.expires_at,
      expires_at: token.expires_at,
      scopes: scopes,
      token_type: Map.get(token, :token_type),
      refresh_token: token.refresh_token,
      token: token.access_token
    }
  end

  @doc """
  Fetches the fields to populate the info section of the `Ueberauth.Auth` struct.
  """
  def info(conn) do
    user = conn.private.snowflake_user

    %Info{
      email: user.email,
      name: user.username
    }
  end

  @doc """
  Stores the raw information (including the token) obtained from the snowflake callback.
  """
  def extra(conn) do
    %Extra{
      raw_info: %{
        snowflake_login: conn.private.snowflake_login,
        snowflake_oauth: conn.private.snowflake_oauth,
        user: conn.private.snowflake_user
      }
    }
  end

  defp fetch_user(conn, token) do
    username = token.token.other_params["username"]
    config = Application.get_env(:ueberauth, __MODULE__, [])
    config = Application.get_env(:ueberauth, __MODULE__, [])

    {:ok, %{token: snowflake_token} = snowflake_login_result} =
      SnowflakeEx.HTTPClient.oauth_login(
        Application.get_env(:inlinerun, :snowflake_url),
        config[:account_name],
        config[:warehouse],
        config[:database],
        config[:model],
        username,
        token.token.access_token,
        config[:role],
        %{}
      )

    {:ok, output} =
      SnowflakeEx.HTTPClient.query(
        Application.get_env(:inlinerun, :snowflake_url),
        snowflake_token,
        "describe user #{username}",
        []
      )

    data =
      output.rows
      |> Enum.map(fn [property, value, default, description] ->
        %{property: property, value: value, default: default, description: description}
      end)

    email =
      Enum.find(data, fn %{property: property} -> property == "EMAIL" end)
      |> Map.get(:value)

    IO.inspect conn
    |> merge_private(
      snowflake_login: snowflake_login_result,
      snowflake_oauth: token.token,
      foobar: snowflake_login_result,
      snowflake_user: %{email: email, username: username}
    )
  end

  defp with_param(opts, key, conn) do
    if value = conn.params[to_string(key)], do: Keyword.put(opts, key, value), else: opts
  end

  defp with_optional(opts, key, conn) do
    if option(conn, key), do: Keyword.put(opts, key, option(conn, key)), else: opts
  end

  defp oauth_client_options_from_conn(conn) do
    base_options = [redirect_uri: callback_url(conn)]
    request_options = conn.private[:ueberauth_request_options].options

    case {request_options[:client_id], request_options[:client_secret]} do
      {nil, _} -> base_options
      {_, nil} -> base_options
      {id, secret} -> [client_id: id, client_secret: secret] ++ base_options
    end
  end

  defp option(conn, key) do
    Keyword.get(options(conn), key, Keyword.get(default_options(), key))
  end
end
