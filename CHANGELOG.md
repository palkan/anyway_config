# Change log

## 2.0.0-dev

- **Require Ruby >= 2.5.0.**

## 1.4.3 (2019-02-04)

- Add a temporary fix for JRuby regression [#5550](https://github.com/jruby/jruby/issues/5550). ([@palkan][])

## 1.4.2 (2018-01-05)

- Fix: detect Rails by presence of `Rails::VERSION` (instead of just `Rails`). ([@palkan][])

## 1.4.1 (2018-10-30)

- Add `.flag_options` to mark some params as flags (value-less) for OptionParse. ([@palkan][])

## 1.4.0 (2018-10-29)

- Add OptionParse integration ([@jastkand][])

  See more https://github.com/palkan/anyway_config/pull/18

- Use underscored config name as an env prefix. ([@palkan][])

  For a config class:

  ```ruby
  class MyApp < Anyway::Config
  end
  ```

  Before this change we use `MYAPP_` prefix, now it's `MY_APP_`.

  You can specify the prefix explictly:

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

  See more https://github.com/palkan/anyway_config/pull/10

## 1.1.2 (2017-11-19)

- Enable aliases for YAML. ([@onemanstartup][])

## 1.1.1 (2017-10-21)

- Return deep duplicate of a Hash in `Env#fetch`. ([@palkan][])

## 1.1.0 (2017-10-06)

- Add `#to_h` method. ([@palkan][])

See [#4](https://github.com/palkan/anyway_config/issues/4).

- Make it possible to extend configuration parameters. ([@palkan][])

## 1.0.0 (2017-06-20)

- Lazy load and parse ENV configurtaion. ([@palkan][])

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
