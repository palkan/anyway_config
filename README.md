[![Build Status](https://travis-ci.org/palkan/anyway_config.svg?branch=master)](https://travis-ci.org/palkan/anyway_config)

# Anyway Config

Rails plugin configuration using any source: YAML, _secrets_, environment.

Requires Rails 4.

## Installation

Configure your gemspec

```ruby
Gem::Specification.new do |s|
  ...
  s.add_dependancy 'anyway_config', "~>0.1"
  ...
end
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install anyway_config

## Usage

### Basic

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

Your config will be filled up with values from `RAILS_ROOT/config/my_cool_gem.yml`, `Rails.application.secrets.my_cool_gem` (if using Rails) and `ENV['MYCOOLGEM_*']`.  

### Customize name

If you want to load config params from, for example, "cool.yml" (secrets, env), just add one line:

```ruby
module MyCoolGem
  class Config < Anyway::Config
    config_name :cool
    attr_config user: 'root', password: 'root', host: 'localhost', options: {}
  end
end
```

### How to set env vars

Environmental variables for your config should start with your module name (or config name if any), uppercased and underscore-free.

For example, if your module is called "MyCoolGem" then your env var "MYCOOLGEM_PASSWORD" is used as `config.password`.

*Anyway Config* supports nested (_hashed_) environmental variables. Just separate keys with double-underscore.
For example, "MYCOOLGEM_OPTIONS__VERBOSE" is transformed to `config.options.verbose`.


### Config clear and reload

You can use `clear` and `reload` functions on your config (which do exactly what they state).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request