module Pop3Client
  module Commands
    module Dele
      def dele(msg : Int32) : String
        raise NotConnectedError.new("Not connected") unless connected?
        raise ProtocolError.new("Not authenticated") unless authenticated?

        send_line "DELE #{msg}"

        line = sock!.gets
        raise ProtocolError.new("No response to DELE") unless line
        line = line.rstrip
        raise ProtocolError.new("DELE rejected: #{line}") unless ok?(line)
        line
      end
    end
  end
end

# include into Client

class Pop3Client::Client
  include Pop3Client::Commands::Dele
end
