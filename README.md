[![Gem Version](https://badge.fury.io/rb/anyway_config.svg)](https://rubygems.org/gems/anyway_config) [![Build Status](https://travis-ci.org/palkan/anyway_config.svg?branch=master)](https://travis-ci.org/palkan/anyway_config)

# Anyway Config

Rails/Ruby plugin/application configuration tool which allows you to load parameters from different sources: YAML, Rails secrets, environment.

Allows you to easily follow the [twelve-factor application](https://12factor.net/config) principles and adds zero complexity to your development process.

Libraries using Anyway Config:

- [Influxer](https://github.com/palkan/influxer)

- [AnyCable](https://github.com/anycable/anycable)

- [Sniffer](https://github.com/aderyabin/sniffer)

- [and others](https://github.com/palkan/anyway_config/network/dependents).

## Installation

1) Adding to a gem:

```ruby
# my-cool-gem.gemspec
Gem::Specification.new do |spec|
  ...
  spec.add_dependency "anyway_config", "~> 1.0"
  ...
end
```

2) Adding to your project:

```ruby
# Gemfile
gem "anyway_config", "~> 1.0"
```

3) Install globally:

```sh
$ gem install anyway_config
```

## Usage

### Pre-defined configuration

Create configuration class:

```ruby
require 'anyway'

module MyCoolGem
  class Config < Anyway::Config
    attr_config user: 'root', password: 'root', host: 'localhost'
  end
end
```

`attr_config` creates accessors and default values. If you don't need default values just write:

```ruby
attr_config :user, :password, host: 'localhost'
```

Then create an instance of the config class and use it:

```ruby
module MyCoolGem
  def self.config
    @config ||= Config.new
  end
end

MyCoolGem.config.user #=> 'root'
```

#### Customize name

By default, Anyway Config uses the namespace (the outer module name) as the config name, but you can set it manually:

```ruby
module MyCoolGem
  class Config < Anyway::Config
    config_name :cool
    attr_config user: 'root', password: 'root', host: 'localhost', options: {}
  end
end
```

#### Customize env variable names prefix

By default, Anyway Config uses underscored config name as a prefix for env variable names (e.g.
`config_name :my_app` will result to parsing `MY_APP_HOST` variable). You can set env prefix
explicitly, and it will be used as is:

```ruby
module MyCoolGem
  class Config < Anyway::Config
    config_name :cool_gem
    env_prefix :really_cool # now variables, starting wih `REALLY_COOL_`, will be parsed
    attr_config user: 'root', password: 'root', host: 'localhost', options: {}
  end
end
```

#### Provide explicit values

Sometimes it's useful to set some parameters explicitly during config initialization.
You can do that using `overrides` option:

```ruby
config = MyCoolGem::Config.new(
  overrides: {
    user: 'john',
    password: 'rubyisnotdead'
  }
)

# The value would not be overriden from other sources (such as YML file, env)
config.user == 'john'
```

### Dynamic configuration

You can also create configuration objects without pre-defined schema (just like `Rails.application.config_for` but more [powerful](#railsapplicationconfig_for-vs-anywayconfigfor)):

```ruby
# load data from config/my_app.yml, secrets.my_app (if using Rails), ENV["MYAPP_*"]
config = Anyway::Config.for(:my_app)
```

### Using with Rails

Your config will be filled up with values from the following sources (ordered by priority from low to high):

- `RAILS_ROOT/config/my_cool_gem.yml` (for the current `RAILS_ENV`, supports `ERB`)

- `Rails.application.secrets.my_cool_gem`

- `ENV['MYCOOLGEM_*']`.

### Using with Ruby

By default, Anyway Config is looking for a config YAML at `./config/<config-name>.yml`. You can override this setting
through special environment variable – 'MYGEM_CONF' – containing the path to the YAML file.

Environmental variables work the same way as with Rails.


### Config clear and reload

There are `#clear` and `#reload` functions on your config (which do exactly what they state).

Note: `#reload` also accepts `overrides` key to provide explicit values (see above).

### OptionParser integration

It's possible to use config as option parser (e.g. for CLI apps/libraries). It uses
[`optparse`](https://ruby-doc.org/stdlib-2.5.1/libdoc/optparse/rdoc/OptionParser.html) under the hood.

Example usage:

```ruby
class MyConfig < Anyway::Config
  attr_config :host, :log_level, :concurrency, :debug, server_args: {}

  # specify which options shouldn't be handled by option parser
  ignore_options :server_args

  # provide description for options
  describe_options(
    concurrency: "number of threads to use"
  )

  # mark some options as flag
  flag_options :debug

  # extend an option parser object (i.e. add banner or version/help handlers)
  extend_options do |parser, config|
    parser.banner = "mycli [options]"

    parser.on("--server-args VALUE") do |value|
      config.server_args = JSON.parse(value)
    end

    parser.on_tail "-h", "--help" do
      puts parser
    end
  end
end

config = MyConfig.new

config.parse_options!(%w(--host localhost --port 3333 --log-level debug))

config.host # => "localhost"
config.port # => 3333
config.log_level # => "debug"

# Get the instance of OptionParser
config.option_parser
```

## `Rails.application.config_for` vs `Anyway::Config.for`

Rails 4.2 introduced new feature: `Rails.application.config_for`. It looks very similar to
`Anyway::Config.for`, but there are some differences:

| Feature       | Rails         | Anyway Config |
| ------------- |:-------------:| -----:|
| load data from `config/app.yml`     | yes | yes |
| load data from `secrets`      | no      |   yes |
| load data from environment | no   |   yes |
| return Hash with indifferent access | no | yes |
| support ERB within `config/app.yml` | yes | yes* |
| raise errors if file doesn't exist | yes | no |

<sub><sup>*</sup>make sure that ERB is loaded</sub>

But the main advantage of Anyway::Config is that it can be used [without Rails](#using-with-ruby)!)

## How to set env vars

Environmental variables for your config should start with your config name, uppercased and underscore-free.

For example, if your module is called "MyCoolGem" then the env var "MYCOOLGEM_PASSWORD" is used as `config.password`.

Environment variables are type-casted (case-insensitive).

Examples:

- `"True"`, `"t"` and `"yes"` to `true`;

- `"False"`, `"f"` and `"no"` to `false`;

- `"nil"` and `"null"` to `nil` (do you really need it?);

- `"123"` to 123 and `"3.14"` to 3.14.

*Anyway Config* supports nested (_hashed_) env variables. Just separate keys with double-underscore.
For example, "MYCOOLGEM_OPTIONS__VERBOSE" is parsed as `config.options["verbose"]`.

Array values are also supported:

```ruby
# Suppose ENV["MYCOOLGEM_IDS"] = '1,2,3'
config.ids #=> [1,2,3]
```

If you want to provide a text-like env variable which contains commas then wrap it into quotes:

```ruby
MYCOOLGEM="Nif-Nif, Naf-Naf and Nouf-Nouf"
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
