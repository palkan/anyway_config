# Where to find the API

The README is the API reference: https://github.com/palkan/anyway_config#readme.
The installed copy is at `$(bundle info anyway_config --path)/README.md`.
Read the section that you need. The source is in `lib/anyway/` of the same directory.

| Task | README section |
|---|---|
| Declare attributes, defaults, boolean predicates, override readers with `super` | [Configuration classes](https://github.com/palkan/anyway_config#configuration-classes) |
| Change the config name or the ENV prefix (`config_name`, `env_prefix`) | [Config name](https://github.com/palkan/anyway_config#config-name), [Customize env variable names prefix](https://github.com/palkan/anyway_config#customize-env-variable-names-prefix) |
| Pass explicit values, reload a config | [Explicit values](https://github.com/palkan/anyway_config#explicit-values), [Reload configuration](https://github.com/palkan/anyway_config#reload-configuration) |
| Load a config without a class (`Anyway::Config.for(:name)`) | [Dynamic configuration](https://github.com/palkan/anyway_config#dynamic-configuration) |
| `required` (with `env:`), `on_load`, `raise_validation_error`, `ANYWAY_SUPPRESS_VALIDATIONS` | [Validation and callbacks](https://github.com/palkan/anyway_config#validation-and-callbacks) |
| Detect typos in YAML and credentials (`enforce_config_schema`, `rescue_unknown_attributes_with`) | [Enforcing config schema](https://github.com/palkan/anyway_config#enforcing-config-schema) |
| Source priority in Rails, YAML lookup path, `<NAME>_CONF`, credentials | [Data population](https://github.com/palkan/anyway_config#data-population) |
| `default:` key, environment-free YAML, `known_environments` | [Multi-env configuration](https://github.com/palkan/anyway_config#multi-env-configuration) |
| `config/configs` vs `app/configs`, static configs, inflections | [Organizing configs](https://github.com/palkan/anyway_config#organizing-configs) |
| `anyway:install`, `anyway:config`, `anyway:app_config` generators | [Generators](https://github.com/palkan/anyway_config#generators) |
| Use configs in `config/puma.rb` or before Rails loads | [Loading Anyway Config before Rails](https://github.com/palkan/anyway_config#loading-anyway-config-before-rails) |
| Plain Ruby apps and gems | [Using with Ruby](https://github.com/palkan/anyway_config#using-with-ruby) |
| ENV names, nested keys (`__`), auto-casting, arrays | [Environment variables](https://github.com/palkan/anyway_config#environment-variables) |
| `coerce_types`, built-in types, custom deserializers, `disable_auto_cast!` | [Type coercion](https://github.com/palkan/anyway_config#type-coercion) |
| `*.local.yml`, local credentials | [Local files](https://github.com/palkan/anyway_config#local-files) |
| Doppler, EJSON, custom loaders, loader order | [Data loaders](https://github.com/palkan/anyway_config#data-loaders) |
| Find where a value came from (`to_source_trace`, `pp config`) | [Tracing](https://github.com/palkan/anyway_config#tracing) |
| Pattern matching on configs | [Pattern matching](https://github.com/palkan/anyway_config#pattern-matching) |
| `with_env` and other test helpers | [Test helpers](https://github.com/palkan/anyway_config#test-helpers) |
| Build a CLI from a config (`OptionParser`) | [OptionParser integration](https://github.com/palkan/anyway_config#optionparser-integration) |
| RBS signatures for config classes | [RBS support](https://github.com/palkan/anyway_config#rbs-support) |

