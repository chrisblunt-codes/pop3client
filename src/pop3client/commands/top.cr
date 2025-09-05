module Pop3Client
  module Commands
    module Top
      def top(msg : Int32, lines : Int32) : String
        raise NotConnectedError.new("Not connected") unless connected?
        raise ProtocolError.new("Not authenticated") unless authenticated?

        send_line "TOP #{msg} #{lines}"

        line = sock!.gets
        raise ProtocolError.new("No response to RETR") unless line
        line = line.rstrip
        raise ProtocolError.new("TOP rejected: #{line}") unless ok?(line)
        
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
  include Pop3Client::Commands::Top
end
