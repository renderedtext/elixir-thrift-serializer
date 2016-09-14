defmodule ElixirThriftSerializer do
  require Logger

  #converts from binary to elixir using a Thrift struct definition
  #struct_definition should look something like this: {:struct, {:models_types, :User}}
  def binary_to_elixir(record_binary, struct_definition, to_elixir_function) do
    try do

      with({:ok, memory_buffer_transport} <- :thrift_memory_buffer.new(record_binary),
           {:ok, binary_protocol} <- :thrift_binary_protocol.new(memory_buffer_transport),
           {_, {:ok, record}} <- :thrift_protocol.read(binary_protocol, struct_definition)) do

             #{:ok, ElixirThrift.Struct.to_elixir(record, struct_definition)}
             {:ok, to_elixir_function.(record, struct_definition)}

      end

    rescue _ ->
        Logger.error "Unable to decode!"
        {:error, :cant_decode}
    end
  end

  #converts from elixir to binary using a Thrift struct definition
  #struct_definition should look something like this: {:struct, {:models_types, :User}}
  def elixir_to_binary(struct_to_binarise, struct_definition, to_erlang_function) do
      with({:ok, tf} <- :thrift_memory_buffer.new_transport_factory(),
          {:ok, pf} <- :thrift_binary_protocol.new_protocol_factory(tf, []),
          {:ok, binary_protocol} <- pf.()) do

            #proto = ElixirThrift.Struct.to_erlang(struct_to_binarise, struct_definition)
            proto = to_erlang_function.(struct_to_binarise, struct_definition)
            |> write_proto(binary_protocol, struct_definition)

            {_, data} = :thrift_protocol.flush_transport(proto)
            :erlang.iolist_to_binary(data)
          end
  end

  defp write_proto(thrift_struct, protocol, struct_definition) do
    {proto, :ok} = :thrift_protocol.write(protocol, {struct_definition, thrift_struct})
    proto
  end
end
