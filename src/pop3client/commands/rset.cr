module Pop3Client
  module Commands
    module Rset
      # Resets the POP3 session state.
      #
      # Sends the `RSET` command to unmark any messages previously marked
      # for deletion in the current session. Messages will remain available
      # until explicitly deleted and the session is ended with `QUIT`.
      #
      # Returns:
      # * The server response line (e.g. `"+OK maildrop has N messages"`).
      #
      # Raises:
      # * NotConnectedError – if the client is not connected.
      # * ProtocolError – if the client is not authenticated or the server rejects the command.
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
