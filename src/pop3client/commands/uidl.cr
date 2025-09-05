module Pop3Client
  module Commands
    module Uidl
      def uidl(msg : Int32? = nil) : Array(String)
        raise NotConnectedError.new("Not connected") unless connected?
        raise ProtocolError.new("Not authenticated") unless authenticated?

        if msg
          # Single-line response: "+OK <msg> <size>"
          send_line "UIDL #{msg}"

          line = sock!.gets
          raise ProtocolError.new("No response to UIDL") unless line
          line = line.rstrip

          raise ProtocolError.new("UIDL rejected: #{line}") unless ok?(line)

          # Return just "msg size" for consistency with multi-line form
          return [line.sub(/\A\+OK\s+/, "")]
        else
          # Multi-line response: first status line, then "n size" lines, then "."
          send_line "UIDL"

          status = @socket.not_nil!.gets
          raise ProtocolError.new("No response to UIDL") unless status
          status = status.rstrip
          raise ProtocolError.new("UIDL rejected: #{status}") unless ok?(status)

          lines = [] of String
          while line = sock!.gets
            line = line.rstrip
            break if line == "."
            lines << line
          end

          return lines
        end
      end
    end
  end
end

# include into Client

class Pop3Client::Client
  include Pop3Client::Commands::Uidl
end
