# Sensingplaza

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sensingplaza'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sensingplaza

## Usage

```ruby
require "sensingplaza"

splz = Sensingplaza::Client.new
splz.mailaddress = "your@mailaddress"
```

### getting data

```ruby
sensorkey = "1234abcd"
datetime = "2018-07-05 12:00:00"

data = splz.get_data(sensorkey, datetime)
```

Other getting methods

```ruby
get_period_data(sensorkey, start_datetime, end_datetime)
get_last_data(sensorkey)

get_image(sensorkey, datetime)
get_period_image(sensorkey, start_datetime, end_datetime)
```

### pushing data

```ruby
sensorkey = "1234abcd"
datetime = "2018-07-05 12:00:00"
value = 12.3

splz.push_data(sensorkey, value, datetime)
```
If datetime is nil, using now datetime. But, I do not recommend it much :)


Other pushing methods

```ruby
push_image(sensorkey, imagedata, datetime)
```

### other

getting sensor information

```ruby
get_sensor_info(sensorkey)
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ysomei/sensingplaza.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
