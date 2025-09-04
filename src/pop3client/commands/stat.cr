module Pop3Client
  module Commands
    module Stat
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
