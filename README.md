# sonyflake

A Crystal port of [sony/sonyflake](https://github.com/sony/sonyflake)

## Installation

1. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  sonyflake:
    github: BecauseOfProg/sonyflake
```

2. Run `shards install`

## Usage

```crystal
require "sonyflake"
settings = Sonyflake::Settings.new(start_time: Time.utc(2020, 1, 1), machine_id: 1)

sonyflake = Sonyflake.new_sonyflake(settings)
puts sonyflake.next_id # => 302603879411875841
puts Sonyflake.get_instance.next_id # => 302603879411941377
```

## Contributing

1. Fork it (<https://github.com/BecauseOfProg/sonyflake/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Whaxion](https://github.com/Whaxion) - creator and maintainer
