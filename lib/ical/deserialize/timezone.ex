defmodule ICal.Deserialize.Timezone do
  @moduledoc false

  alias ICal.Deserialize

  @type maybe_timezone :: nil | ICal.Timezone.t()
  @spec one(data :: binary()) :: {data :: binary, maybe_timezone}
  def one(data) do
    next(data, %ICal.Timezone{})
  end

  @spec next(data :: binary(), ICal.Timezone.maybe()) ::
          {data :: binary, nil | ICal.Timezone.t()}
  defp next(<<>> = data, _timezone) do
    {data, nil}
  end

  defp next(<<"END:VTIMEZONE", data::binary>>, timezone) do
    if timezone.id == nil do
      {data, nil}
    else
      {data, timezone}
    end
  end

  defp next(<<"TZID", data::binary>>, timezone) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.value(data)
    timezone = %{timezone | id: value}
    next(data, timezone)
  end

  defp next(<<"TZURL", data::binary>>, timezone) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.value(data)
    timezone = %{timezone | url: value}
    next(data, timezone)
  end

  defp next(<<"LAST-MODIFIED", data::binary>>, timezone) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.value(data)
    date = Deserialize.to_date_in_timezone(value, "Etc/UTC")
    timezone = %{timezone | modified: date}
    next(data, timezone)
  end

  defp next(<<"BEGIN:STANDARD", data::binary>>, timezone) do
    {data, properties} =
      data
      |> Deserialize.skip_line()
      |> next_property(%ICal.Timezone.Properties{})

    if properties != nil do
      next(data, %{timezone | standard: timezone.standard ++ [properties]})
    else
      next(data, timezone)
    end
  end

  defp next(<<"BEGIN:DAYLIGHT", data::binary>>, timezone) do
    {data, properties} =
      data
      |> Deserialize.skip_line()
      |> next_property(%ICal.Timezone.Properties{})

    if properties != nil do
      next(data, %{timezone | daylight: timezone.daylight ++ [properties]})
    else
      next(data, timezone)
    end
  end

  # prevent losing other non-standard headers
  defp next(<<"X-", data::binary>>, timezone) do
    {data, timezone} = ICal.Deserialize.parse_custom_property(data, timezone)
    next(data, timezone)
  end

  defp next(data, timezone) do
    data
    |> Deserialize.skip_line()
    |> next(timezone)
  end

  @spec next_property(data :: binary(), ICal.Timezone.Properties.maybe()) ::
          {data :: binary, nil | ICal.Timezone.Properties.t()}
  defp next_property(<<>> = data, _properties) do
    {data, nil}
  end

  defp next_property(<<"END:", data::binary>>, properties) do
    # this is a wee bit cheeky: technically it should be checking for
    # "END:#{type}" but that is slower and should never occur in well-formed
    # data
    data = Deserialize.skip_line(data)

    if properties.dtstart != nil do
      {data, properties}
    else
      {data, nil}
    end
  end

  defp next_property(<<"DTSTART", data::binary>>, properties) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.value(data)
    date = Deserialize.to_local_date(value)
    properties = %{properties | dtstart: date}
    next_property(data, properties)
  end

  defp next_property(<<"RRULE", data::binary>>, properties) do
    data = Deserialize.skip_params(data)
    {data, params} = Deserialize.param_list(data)
    rule = Deserialize.Recurrence.from_params(params)
    properties = %{properties | rrule: rule}
    next_property(data, properties)
  end

  defp next_property(<<"TZNAME", data::binary>>, properties) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.value(data)
    properties = %{properties | names: properties.names ++ [value]}
    next_property(data, properties)
  end

  defp next_property(<<"TZOFFSETFROM", data::binary>>, properties) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.value(data)

    properties =
      case Deserialize.to_integer(value) do
        nil -> properties
        offset -> %{properties | offsets: %{properties.offsets | from: offset}}
      end

    next_property(data, properties)
  end

  defp next_property(<<"TZOFFSETTO", data::binary>>, properties) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.value(data)

    properties =
      case Deserialize.to_integer(value) do
        nil -> properties
        offset -> %{properties | offsets: %{properties.offsets | to: offset}}
      end

    next_property(data, properties)
  end

  defp next_property(<<"COMMENT", data::binary>>, properties) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.value(data)
    properties = %{properties | comments: properties.comments ++ [value]}
    next_property(data, properties)
  end

  defp next_property(<<"RDATE", data::binary>>, properties) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.value(data)
    date = Deserialize.to_local_date(value)
    properties = %{properties | rdates: properties.rdates ++ [date]}
    next_property(data, properties)
  end

  # prevent losing other non-standard headers
  defp next_property(<<"X-", data::binary>>, properties) do
    {data, key} = Deserialize.rest_of_key(data, "X-")
    {data, params} = Deserialize.params(data)
    {data, value} = Deserialize.value(data)

    custom_entry = %{params: params, value: value}
    custom_properties = Map.put(properties.custom_properties, key, custom_entry)
    next_property(data, %{properties | custom_properties: custom_properties})
  end

  defp next_property(data, properties) do
    data
    |> Deserialize.skip_line()
    |> next_property(properties)
  end

  # this array is generated by running `mix run ./priv/generate_windows_tz_mapping.exs`
  # DO NOT EDIT THIS ARRAY BY HAND!
  windows_tz =
    [
      {"AUS Central Standard Time", "Australia/Darwin"},
      {"AUS Eastern Standard Time", "Australia/Sydney"},
      {"Afghanistan Standard Time", "Asia/Kabul"},
      {"Alaskan Standard Time", "America/Anchorage"},
      {"Aleutian Standard Time", "America/Adak"},
      {"Altai Standard Time", "Asia/Barnaul"},
      {"Arab Standard Time", "Asia/Riyadh"},
      {"Arabian Standard Time", "Etc/GMT-4"},
      {"Arabic Standard Time", "Asia/Baghdad"},
      {"Argentina Standard Time", "America/Buenos_Aires"},
      {"Astrakhan Standard Time", "Europe/Astrakhan"},
      {"Atlantic Standard Time", "America/Halifax"},
      {"Aus Central W. Standard Time", "Australia/Eucla"},
      {"Azerbaijan Standard Time", "Asia/Baku"},
      {"Azores Standard Time", "Atlantic/Azores"},
      {"Bahia Standard Time", "America/Bahia"},
      {"Bangladesh Standard Time", "Asia/Dhaka"},
      {"Belarus Standard Time", "Europe/Minsk"},
      {"Bougainville Standard Time", "Pacific/Bougainville"},
      {"Canada Central Standard Time", "America/Regina"},
      {"Cape Verde Standard Time", "Etc/GMT+1"},
      {"Caucasus Standard Time", "Asia/Yerevan"},
      {"Cen. Australia Standard Time", "Australia/Adelaide"},
      {"Central America Standard Time", "Etc/GMT+6"},
      {"Central Asia Standard Time", "Etc/GMT-6"},
      {"Central Brazilian Standard Time", "America/Cuiaba"},
      {"Central Europe Standard Time", "Europe/Budapest"},
      {"Central European Standard Time", "Europe/Warsaw"},
      {"Central Pacific Standard Time", "Etc/GMT-11"},
      {"Central Standard Time", "America/Chicago"},
      {"Central Standard Time (Mexico)", "America/Mexico_City"},
      {"Chatham Islands Standard Time", "Pacific/Chatham"},
      {"China Standard Time", "Asia/Shanghai"},
      {"Cuba Standard Time", "America/Havana"},
      {"Dateline Standard Time", "Etc/GMT+12"},
      {"E. Africa Standard Time", "Etc/GMT-3"},
      {"E. Australia Standard Time", "Australia/Brisbane"},
      {"E. Europe Standard Time", "Europe/Chisinau"},
      {"E. South America Standard Time", "America/Sao_Paulo"},
      {"Easter Island Standard Time", "Pacific/Easter"},
      {"Eastern Standard Time", "America/New_York"},
      {"Eastern Standard Time (Mexico)", "America/Cancun"},
      {"Egypt Standard Time", "Africa/Cairo"},
      {"Ekaterinburg Standard Time", "Asia/Yekaterinburg"},
      {"FLE Standard Time", "Europe/Kiev"},
      {"Fiji Standard Time", "Pacific/Fiji"},
      {"GMT Standard Time", "Europe/London"},
      {"GTB Standard Time", "Europe/Bucharest"},
      {"Georgian Standard Time", "Asia/Tbilisi"},
      {"Greenland Standard Time", "America/Godthab"},
      {"Greenwich Standard Time", "Atlantic/Reykjavik"},
      {"Haiti Standard Time", "America/Port-au-Prince"},
      {"Hawaiian Standard Time", "Etc/GMT+10"},
      {"India Standard Time", "Asia/Calcutta"},
      {"Iran Standard Time", "Asia/Tehran"},
      {"Israel Standard Time", "Asia/Jerusalem"},
      {"Jordan Standard Time", "Asia/Amman"},
      {"Kaliningrad Standard Time", "Europe/Kaliningrad"},
      {"Korea Standard Time", "Asia/Seoul"},
      {"Libya Standard Time", "Africa/Tripoli"},
      {"Line Islands Standard Time", "Etc/GMT-14"},
      {"Lord Howe Standard Time", "Australia/Lord_Howe"},
      {"Magadan Standard Time", "Asia/Magadan"},
      {"Magallanes Standard Time", "America/Punta_Arenas"},
      {"Marquesas Standard Time", "Pacific/Marquesas"},
      {"Mauritius Standard Time", "Indian/Mauritius"},
      {"Middle East Standard Time", "Asia/Beirut"},
      {"Montevideo Standard Time", "America/Montevideo"},
      {"Morocco Standard Time", "Africa/Casablanca"},
      {"Mountain Standard Time", "America/Denver"},
      {"Mountain Standard Time (Mexico)", "America/Mazatlan"},
      {"Myanmar Standard Time", "Asia/Rangoon"},
      {"N. Central Asia Standard Time", "Asia/Novosibirsk"},
      {"Namibia Standard Time", "Africa/Windhoek"},
      {"Nepal Standard Time", "Asia/Katmandu"},
      {"New Zealand Standard Time", "Pacific/Auckland"},
      {"Newfoundland Standard Time", "America/St_Johns"},
      {"Norfolk Standard Time", "Pacific/Norfolk"},
      {"North Asia East Standard Time", "Asia/Irkutsk"},
      {"North Asia Standard Time", "Asia/Krasnoyarsk"},
      {"North Korea Standard Time", "Asia/Pyongyang"},
      {"Omsk Standard Time", "Asia/Omsk"},
      {"Pacific SA Standard Time", "America/Santiago"},
      {"Pacific Standard Time", "America/Los_Angeles"},
      {"Pacific Standard Time (Mexico)", "America/Tijuana"},
      {"Pakistan Standard Time", "Asia/Karachi"},
      {"Paraguay Standard Time", "America/Asuncion"},
      {"Qyzylorda Standard Time", "Asia/Qyzylorda"},
      {"Romance Standard Time", "Europe/Paris"},
      {"Russia Time Zone 10", "Asia/Srednekolymsk"},
      {"Russia Time Zone 11", "Asia/Kamchatka"},
      {"Russia Time Zone 3", "Europe/Samara"},
      {"Russian Standard Time", "Europe/Moscow"},
      {"SA Eastern Standard Time", "Etc/GMT+3"},
      {"SA Pacific Standard Time", "Etc/GMT+5"},
      {"SA Western Standard Time", "Etc/GMT+4"},
      {"SE Asia Standard Time", "Etc/GMT-7"},
      {"Saint Pierre Standard Time", "America/Miquelon"},
      {"Sakhalin Standard Time", "Asia/Sakhalin"},
      {"Samoa Standard Time", "Pacific/Apia"},
      {"Sao Tome Standard Time", "Africa/Sao_Tome"},
      {"Saratov Standard Time", "Europe/Saratov"},
      {"Singapore Standard Time", "Etc/GMT-8"},
      {"South Africa Standard Time", "Etc/GMT-2"},
      {"South Sudan Standard Time", "Africa/Juba"},
      {"Sri Lanka Standard Time", "Asia/Colombo"},
      {"Sudan Standard Time", "Africa/Khartoum"},
      {"Syria Standard Time", "Asia/Damascus"},
      {"Taipei Standard Time", "Asia/Taipei"},
      {"Tasmania Standard Time", "Australia/Hobart"},
      {"Tocantins Standard Time", "America/Araguaina"},
      {"Tokyo Standard Time", "Etc/GMT-9"},
      {"Tomsk Standard Time", "Asia/Tomsk"},
      {"Tonga Standard Time", "Pacific/Tongatapu"},
      {"Transbaikal Standard Time", "Asia/Chita"},
      {"Turkey Standard Time", "Europe/Istanbul"},
      {"Turks And Caicos Standard Time", "America/Grand_Turk"},
      {"US Eastern Standard Time", "America/Indianapolis"},
      {"US Mountain Standard Time", "Etc/GMT+7"},
      {"UTC", "Etc/UTC Etc/GMT"},
      {"UTC+12", "Etc/GMT-12"},
      {"UTC+13", "Etc/GMT-13"},
      {"UTC-02", "Etc/GMT+2"},
      {"UTC-08", "Etc/GMT+8"},
      {"UTC-09", "Etc/GMT+9"},
      {"UTC-11", "Etc/GMT+11"},
      {"Ulaanbaatar Standard Time", "Asia/Ulaanbaatar"},
      {"Venezuela Standard Time", "America/Caracas"},
      {"Vladivostok Standard Time", "Asia/Vladivostok"},
      {"Volgograd Standard Time", "Europe/Volgograd"},
      {"W. Australia Standard Time", "Australia/Perth"},
      {"W. Central Africa Standard Time", "Etc/GMT-1"},
      {"W. Europe Standard Time", "Europe/Berlin"},
      {"W. Mongolia Standard Time", "Asia/Hovd"},
      {"West Asia Standard Time", "Etc/GMT-5"},
      {"West Bank Standard Time", "Asia/Hebron"},
      {"West Pacific Standard Time", "Etc/GMT-10"},
      {"Yakutsk Standard Time", "Asia/Yakutsk"},
      {"Yukon Standard Time", "America/Whitehorse"}
    ]

  windows_tz
  |> Enum.each(fn {from, to} ->
    def windows_to_olson(unquote(from)), do: unquote(to)
  end)

  def windows_to_olson(_), do: nil
end
