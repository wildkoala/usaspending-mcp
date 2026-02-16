defmodule UsaspendingMcp.ApiClient do
  @moduledoc """
  HTTP client for the USASpending API (https://api.usaspending.gov).
  """

  @base_url "https://api.usaspending.gov"

  def get(path, params \\ []) do
    url = @base_url <> path

    case Req.get(url, params: params, receive_timeout: 30_000) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, "API returned status #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end

  def post(path, body) do
    url = @base_url <> path

    case Req.post(url, json: body, receive_timeout: 30_000) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, "API returned status #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end
end
