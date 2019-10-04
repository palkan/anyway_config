# Change log

## 2.0.0.pre2 (2019-04-26)

- Fix bug with loading from credentials when local credentials are missing. ([@palkan][])

## 2.0.0.pre (2019-04-26)

- **BREAKING** Changed the way of providing explicit values. ([@palkan][])

  ```ruby
  # BEFORE
  Config.new(overrides: data)

  # AFTER
  Config.new(data)
  ```

- Add Railtie. ([@palkan][])

  `Anyway::Railtie` provides `Anyway::Settings` access via `Rails.applicaiton.configuration.anyway_config`.

  It also adds `app/configs` path to autoload paths (low-level, `ActiveSupport::Dependencies`) to
  make it possible to use configs in the app configuration files.

- Add test helpers. ([@palkan][])

  Added `with_env` helper to test code in the context of the specified
  environment variables.

  Included automatically in RSpec for examples with the `type: :config` meta
  or with the `spec/configs` path.

- Add support for _local_ files. ([@palkan][])

  Now users can store their personal configurations in _local_ files:
  - `<config_name>.local.yml`
  - `config/credentials/local.yml.enc` (for Rails 6).

  Local configs are meant for using in development and only loaded if
  `Anyway::Settings.use_local_files` is `true` (which is true by default if
  `RACK_ENV` or `RAILS_ENV` env variable is equal to `"development"`).

- Add Rails credentials support. ([@palkan][])

  The data from credentials is loaded after the data from YAML config and secrets,
  but before environmental variables (i.e. env variables are _stronger_)

- Update config name inference logic. ([@palkan][])

  Config name is automatically inferred only if:
  - the class name has a form of `<Module>::Config` (`SomeModule::Config => "some_module"`)
  - the class name has a form of `<Something>Config` (`SomeConfig => "some"`)

- Fix config classes inheritance. ([@palkan][])

  Previously, inheritance didn't work due to the lack of proper handling of class-level
  configuration (naming, option parses settings, defaults).

  Now it's possible to extend config classes without breaking the original classes functionality.

  Noticeable features:
  - if `config_name` is explicitly defined on class, it's inherited by subclasses:

  ```ruby
  class MyAppBaseConfig < Anyway::Config
    config_name :my_app
  end

  class MyServiceConfig < MyAppBaseConfig
  end

  MyServiceConfig.config_name #=> "my_app"
  ```

  - defaults are merged leaving the parent class defaults unchanged
  - option parse extension are not overriden, but added to the parent class extensions

- **Require Ruby >= 2.5.0.**

## 1.4.3 (2019-02-04)

- Add a temporary fix for JRuby regression [#5550](https://github.com/jruby/jruby/issues/5550). ([@palkan][])

## 1.4.2 (2018-01-05)

- Fix: detect Rails by presence of `Rails::VERSION` (instead of just `Rails`). ([@palkan][])

## 1.4.1 (2018-10-30)

- Add `.flag_options` to mark some params as flags (value-less) for OptionParse. ([@palkan][])

## 1.4.0 (2018-10-29)

- Add OptionParse integration ([@jastkand][])

  See more [PR#18](https://github.com/palkan/anyway_config/pull/18).

- Use underscored config name as an env prefix. ([@palkan][])

  For a config class:

  ```ruby
  class MyApp < Anyway::Config
  end
  ```

  Before this change we use `MYAPP_` prefix, now it's `MY_APP_`.

  You can specify the prefix explicitly:

  ```ruby
  class MyApp < Anyway::Config
    env_prefix "MYAPP_"
  end
  ```

## 1.3.0 (2018-06-15)

- Ruby 2.2 is no longer supported.

- `Anyway::Config.env_prefix` method is introduced. ([@charlie-wasp][])

## 1.2.0 (2018-02-19)

Now works on JRuby 9.1+.

## 1.1.3 (2017-12-20)

- Allow to pass raw hash with explicit values to `Config.new`. ([@dsalahutdinov][])

  Example:

  ```ruby
  Sniffer::Config.new(
    overrides: {
      enabled: true,
      storage: {capacity: 500}
    }
  )
  ```

  See more [PR#10](https://github.com/palkan/anyway_config/pull/10).

## 1.1.2 (2017-11-19)

- Enable aliases for YAML. ([@onemanstartup][])

## 1.1.1 (2017-10-21)

- Return deep duplicate of a Hash in `Env#fetch`. ([@palkan][])

## 1.1.0 (2017-10-06)

- Add `#to_h` method. ([@palkan][])

See [#4](https://github.com/palkan/anyway_config/issues/4).

- Make it possible to extend configuration parameters. ([@palkan][])

## 1.0.0 (2017-06-20)

- Lazy load and parse ENV configuration. ([@palkan][])

- Add support for ERB in YML configuration. ([@palkan][])

## 0.5.0 (2017-01-20)

- Drop `active_support` dependency. ([@palkan][])

Use custom refinements instead of requiring `active_support`.

No we're dependency-free!

## 0.1.0 (2015-01-20)

Initial version.

[@palkan]: https://github.com/palkan
[@onemanstartup]: https://github.com/onemanstartup
[@dsalahutdinov]: https://github.com/dsalahutdinov
[@charlie-wasp]: https://github.com/charlie-wasp
[@jastkand]: https://github.com/jastkand
