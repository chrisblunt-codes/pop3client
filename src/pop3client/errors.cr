# Copyright 2025 Chris Blunt
# Licensed under the Apache License, Version 2.0

module Pop3Client
  class AlreadyConnectedError < Exception; end
  class ConnectionError       < Exception; end
  class NotConnectedError     < Exception; end
  class Pop3Error             < Exception; end
  class ProtocolError         < Pop3Error; end
  class ResponseError         < Pop3Error; end
end
