defmodule ICal.Serialize.Attachment do
  @moduledoc false
  def to_ics(%ICal.Attachment{} = attachment) do
    params =
      if attachment.mimetype != nil do
        [";FMTTYPE=", attachment.mimetype]
      else
        []
      end

    value_with_extra_params =
      case attachment.data_type do
        :uri -> [?:, attachment.data]
        :cid -> [":CID:", attachment.data]
        :base64 -> [";ENCODING=BASE64;VALUE=BINARY:", attachment.data]
        :base8 -> [";ENCODING=8BIT;VALUE=BINARY:", attachment.data]
      end

    ["ATTACH", params, value_with_extra_params, ?\n]
  end
end
