module Pop3Client
  module Commands
    module Rset
      def rset : String
        raise NotConnectedError.new("Not connected") unless connected?
        raise ProtocolError.new("Not authenticated") unless authenticated?

        send_line "RSET"

        line = sock!.gets
        raise ProtocolError.new("No response to RSET") unless line
        line = line.rstrip
        raise ProtocolError.new("RSET rejected: #{line}") unless ok?(line)
        line
      end
    end
  end
end

# include into Client

class Pop3Client::Client
  include Pop3Client::Commands::Rset
end
