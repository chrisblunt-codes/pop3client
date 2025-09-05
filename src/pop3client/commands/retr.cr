module Pop3Client
  module Commands
    module Retr
      def retr(msg : Int32) : String
        raise NotConnectedError.new("Not connected") unless connected?
        raise ProtocolError.new("Not authenticated") unless authenticated?

        send_line "RETR #{msg}"

        line = sock!.gets
        raise ProtocolError.new("No response to RETR") unless line
        line = line.rstrip
        raise ProtocolError.new("RETR rejected: #{line}") unless ok?(line)
        
        io = IO::Memory.new
        while(line = sock!.gets)
          line = line.rstrip
          break if line == "."
          io << line << "\r\n"
        end

        return io.to_s
      end
    end
  end
end

# include into Client

class Pop3Client::Client
  include Pop3Client::Commands::Retr
end
