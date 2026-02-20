defmodule ICal.Deserialize.RequestStatus do
  @moduledoc false

  alias ICal.Deserialize

  @spec one(data :: binary()) :: {data :: binary(), nil | ICal.RequestStatus.t()}
  def one(data) do
    {data, params} = Deserialize.params(data)
    request_status = %ICal.RequestStatus{language: Map.get(params, "LANGUAGE")}
    code_first(data, <<>>, request_status)
  end

  defp code_first(data, acc, request_status) do
    case data do
      <<?., data::binary>> ->
        code_second(data, acc, <<>>, request_status)

      <<d::utf8, data::binary>> when d >= ?0 and d <= ?9 ->
        code_first(data, <<acc::binary, d::utf8>>, request_status)

      _ ->
        fail(data)
    end
  end

  ## Get the second digit of the code
  defp code_second(data, a, acc, request_status) do
    case data do
      <<?;, data::binary>> ->
        if acc == "" do
          fail(data)
        else
          code = {String.to_integer(a), String.to_integer(acc)}
          desc(data, <<>>, %{request_status | code: code})
        end

      <<?., data::binary>> ->
        code_third(data, a, acc, <<>>, request_status)

      <<d::utf8, data::binary>> when d >= ?0 and d <= ?9 ->
        code_second(data, a, <<acc::binary, d::utf8>>, request_status)

      _ ->
        fail(data)
    end
  end

  ## Get the optional third digit of the code
  defp code_third(data, a, b, acc, request_status) do
    case data do
      <<?;, data::binary>> ->
        if acc == "" do
          fail(data)
        else
          code = {String.to_integer(a), String.to_integer(b), String.to_integer(acc)}
          desc(data, <<>>, %{request_status | code: code})
        end

      <<d::utf8, data::binary>> when d >= ?0 and d <= ?9 ->
        code_third(data, a, b, <<acc::binary, d::utf8>>, request_status)

      _ ->
        fail(data)
    end
  end

  # get the description
  defp desc(data, acc, request_status) do
    case data do
      <<?\\, c::utf8, data::binary>> ->
        desc(data, <<acc::binary, c::utf8>>, request_status)

      <<>> = data ->
        finalize(data, request_status, :description, acc)

      <<?\r, ?\n, data::binary>> ->
        finalize(data, request_status, :description, acc)

      <<?\n, data::binary>> ->
        finalize(data, request_status, :description, acc)

      <<?;, data::binary>> ->
        exception(data, <<>>, %{request_status | description: acc})

      <<c::utf8, data::binary>> ->
        desc(data, <<acc::binary, c::utf8>>, request_status)
    end
  end

  defp exception(data, acc, request_status) do
    case data do
      <<?\\, c::utf8, data::binary>> ->
        exception(data, <<acc::binary, c::utf8>>, request_status)

      <<>> = data ->
        finalize(data, request_status, :exception, acc)

      <<?\r, ?\n, data::binary>> ->
        finalize(data, request_status, :exception, acc)

      <<?\n, data::binary>> ->
        finalize(data, request_status, :exception, acc)

      <<?;, data::binary>> ->
        finalize(Deserialize.skip_line(data), request_status, :exception, acc)

      <<c::utf8, data::binary>> ->
        exception(data, <<acc::binary, c::utf8>>, request_status)
    end
  end

  defp fail(data), do: {Deserialize.skip_line(data), nil}

  defp finalize(data, request_status, _key, ""), do: finalize(data, request_status)

  defp finalize(data, request_status, key, value),
    do: finalize(data, Map.put(request_status, key, value))

  defp finalize(data, %ICal.RequestStatus{} = request_status) do
    if request_status.description == "" do
      {data, nil}
    else
      {data, request_status}
    end
  end
end
