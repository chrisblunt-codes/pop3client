# pop3client

A tiny POP3 client for Crystal.

## Installation

Add this to your `shard.yml`:

```yaml
dependencies:
  pop3client:
    github: chrisblunt-codes/pop3client
```

## Usage

```crystal
require "pop3client"

client = POP3::Client.new("mail.example.com", 110)
client.connect
client.login("user", "pass")
stat = client.stat
if stat[:count] > 0
  list = client.list
  list.each { |line| puts line }
  msg = client.retr(1)
  puts msg
end
client.quit
```

## Roadmap

- [x] Connect and QUIT
- [x] USER / PASS login
- [x] STAT
- [x] LIST
- [x] UIDL
- [x] RETR
- [x] TOP
- [x] DELE
- [x] RSET
- [ ] TLS (STLS / direct)


## Contributing

1. Fork it (<https://github.com/chrisblunt-codes/pop3client/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Chris Blunt](https://github.com/chrisblunt-codes) - creator and maintainer


## License

Copyright 2025 Chris Blunt
Licensed under the Apache License, Version 2.0
SPDX-License-Identifier: Apache-2.0

