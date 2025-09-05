module Pop3Client
  module Commands
    module Stat
      # Retrieves mailbox statistics from the POP3 server.
      #
      # Sends the `STAT` command and returns the number of messages and the
      # total size of the mailbox in octets.
      #
      # Returns:
      # * A `NamedTuple(count: Int32, octets: Int64)` where:
      #   * `count` – number of messages in the mailbox.
      #   * `octets` – total size of all messages in octets.
      #
      # Raises:
      # * NotConnectedError – if the client is not connected.
      # * ProtocolError – if the client is not authenticated, the server
      #   rejects the request, or the response is malformed.
      def stat : NamedTuple(count: Int32, octets: Int64)
        raise NotConnectedError.new("Not connected") unless connected?
        raise ProtocolError.new("Not authenticated") unless authenticated?

        send_line "STAT"
        line = read_line

        unless ok?(line)
          close
          raise ProtocolError.new("STAT rejected: #{line}")
        end

        # Expect "+OK <count> <octets>"
        parts = line.split
        
        # parts[0]="+OK", parts[1]=count, parts[2]=octets
        if parts.size < 3
          raise ProtocolError.new("Malformed STAT response: #{line}")
        end

        count  = parts[1].to_i? || raise ProtocolError.new("Bad count in STAT: #{parts[1]}")
        octets = parts[2].to_i64? || raise ProtocolError.new("Bad octets in STAT: #{parts[2]}")

        { count: count, octets: octets }
      end
    end
  end
end

# include into Client

class Pop3Client::Client
  include Pop3Client::Commands::Stat
end
