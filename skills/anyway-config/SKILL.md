---
name: anyway-config
description: Add, organize, refactor and test application configuration in Rails apps with Anyway Config (`Anyway::Config`). Use when a change needs a new setting, secret, API key, token, URL, env variable, feature toggle or third-party integration credentials; when code reads `ENV[...]`, `Rails.application.credentials`, `config_for` or branches on `Rails.env.production?`; when the user asks where configuration should live or how to stub it in tests.
---

# Anyway Config: configuration in Rails apps

A config class is the only code that knows where a value comes from.
Application code depends on the config object. It never reads `ENV`,
credentials or YAML directly, and it does not branch on `Rails.env`.

This file is the decision procedure. Read these files for details:

- `references/organizing.md`: class placement, sources, boot integration, examples.
- `references/testing.md`: test the config class and the code that uses it.
- `references/docs.md`: the full map of README sections (§10 has the short version). Read the README
  (or the gem source, `bundle info anyway_config --path`) for the API. Do not guess it.

## 1. Look at the project first

1. Find the existing configs: `config/configs/`, `app/configs/`, and `*/config.rb` next to services.
2. Read `ApplicationConfig`. Most apps make it a singleton (`AppConfig.host`).
3. Read the `config.anyway_config.*` lines in `config/application.rb`.
   Note `autoload_static_config_path`, `default_environmental_key` and `enforce_config_schema`.
4. Read `.gitignore`. Check that `config/*.local.yml` and `config/credentials/local.*` are ignored.
5. Follow the conventions that you find. This skill gives the defaults for a new project.

If the gem is not set up yet, run `bin/rails g anyway:install`.

## 2. Decide where the new value goes

```
Is the value a config parameter (it changes between deployments or environments)?
├── no → a constant in the code. Stop.
└── yes
    ├── Is it infrastructure that Rails or a tool reads itself
    │   (PORT, RAILS_MAX_THREADS, DATABASE_URL, RAILS_LOG_LEVEL)?
    │   └── yes → keep it where the tool expects it (puma.rb, database.yml). Stop.
    ├── Does an existing config class own this concern (same service, same subsystem)?
    │   └── yes → add an attribute to that class. Go to §4.
    └── no → create a new config class. Go to §3.
```

Group parameters by concern: one class per integration or subsystem
(`StripeConfig`, `SMTPConfig`, `FlyDeploy::Config`).
Do not make one class per parameter. Do not put everything into `AppConfig`.
`AppConfig` holds app-wide values only: host, port, asset host, global toggles.

## 3. Create a config class

Choose the location:

| The config is used… | Put it in | Notes |
|---|---|---|
| at boot (`config/application.rb`, initializers, routes, `puma.rb`), or app-wide | `config/configs/<name>_config.rb` | Static: not reloaded in development. |
| by one module, service or pack only | next to that code, e.g. `app/services/fly_deploy/config.rb` | Set `config_name` explicitly. Not available before autoloading. |
| at runtime only, and the project keeps such configs in `app/configs/` | `app/configs/<name>_config.rb` | Reloaded in development. |

Generate a class with `bin/rails g anyway:config <name> param1 param2`.
Add `--app` for `app/configs/`. For an in-place class, write it by hand:

```ruby
# app/services/fly_deploy/config.rb
module FlyDeploy
  class Config < ApplicationConfig
    # Without it, the name is "flydeploy" (downcased, not underscored)
    config_name :fly_deploy

    attr_config :api_token, :org_slug,
      rest_api_url: "https://api.machines.dev/v1",
      region: "iad"

    required :api_token, env: :production

    def fake_api? = rest_api_url.include?("fake_fly")
  end
end
```

The config name sets all source keys: `config/fly_deploy.yml`,
`credentials.fly_deploy`, and `FLY_DEPLOY_*` env variables.
If a gem or tool already uses that name (for example, Litestream reads `LITESTREAM_*`),
choose a different name: `config_name :litestream_rails`.

## 4. Choose the source for each value

| Value | Source |
|---|---|
| Non-secret default, same everywhere | `attr_config name: default` |
| Non-secret value that differs per environment | `config/<name>.yml`, per-environment keys |
| Fake value for development and test (stub API URL, test token) | `development:` / `test:` keys in `config/<name>.yml` |
| Secret (API key, password, signing secret) | Rails credentials under `<name>:`, or ENV `<NAME>_<ATTR>` from the deployment platform |
| Personal developer override | `config/<name>.local.yml` or `config/credentials/local.yml.enc` (git-ignored) |
| Value that an operator changes without a deploy | ENV `<NAME>_<ATTR>` |

Load priority, from low to high: attribute defaults → YAML (plus `.local.yml`) →
credentials → ENV → explicit `Config.new(key: value)`.

Do not write `<%= ENV["STRIPE_API_KEY"] %>` in YAML. The ENV loader already maps
`STRIPE_API_KEY` to `StripeConfig#api_key`.

## 5. Write the attributes

- Give a default to each attribute that has a safe value. A `true`/`false` default adds a `?` predicate.
- Mark mandatory values with `required`. Limit it with `env:` (`env: :production`,
  `env: {except: %i[development test]}`) when development can run without the value.
- Add `coerce_types` when ENV must produce an array (`{type: :string, array: true}`)
  or must stay a string (`oauth_scope: :string`, a numeric-looking token).
- Put logic on the config, not in callers:
  - Presence predicate: `def configured? = api_key.present? && secret.present?`
  - Derived value: `def asset_host = super || "#{ssl? ? "https" : "http"}://#{host}"`
  - Adapter for a library: `def to_settings = {address:, port:, user_name: username}.compact`
- Add a comment to an attribute when its purpose or format is not obvious.
- Do not use reserved names (`values`, `to_h`, `clear`, `config_name`, …).
  With the singleton `ApplicationConfig`, also avoid names of class methods (README, issue #120).
- If the project type-checks with RBS (`sig/`, `Steepfile`), add a signature for the new config.
  `MyConfig.to_rbs` generates it from `attr_config`, `coerce_types` and `required`.

## 6. Use the config

- Call the config from application code: `StripeConfig.secret_key`, `AppConfig.analytics_enabled?`.
- Pass the config as a default argument when a class depends on it. Tests can then inject another one:
  `def initialize(config: FlyDeploy::Config)`.
- Turn integrations on by the presence of their settings, not by the environment:
  `provider :github, ... if GithubConfig.oauth_configured?`.
- Configure Rails and gems from configs in `config/application.rb` and initializers.
  See `references/organizing.md` §4.
- A gem that reads only `ENV`: copy the value once in its initializer,
  `ENV["STRIPE_PRIVATE_KEY"] ||= StripeConfig.secret_key`.

## 7. Replace direct reads

| You see | Replace with |
|---|---|
| `ENV["FOO_API_KEY"]` in app code | `FooConfig.api_key` |
| `ENV.fetch("FOO_ENABLED", "false") == "true"` | `attr_config enabled: false` → `FooConfig.enabled?` |
| `Rails.application.credentials.foo[:key]` | `FooConfig.key` (same `foo:` credentials, no change in data) |
| `Rails.application.config_for(:foo)` | `FooConfig` (same `config/foo.yml`) |
| `if Rails.env.production?` to select a value | a per-environment YAML value |
| `if Rails.env.production?` to turn a feature on | a boolean attribute or `configured?` predicate |
| `ENV["X"] \|\| "default"` | `attr_config x: "default"` |

Keep `Rails.env` checks that are about the framework itself (for example, test-only view helpers).

## 8. Test

Read `references/testing.md`. In short:

- Put the test values in the `test:` section of `config/<name>.yml`. CI then needs no secrets.
- Unit-test the config class with `described_class.new(key: value)` and `with_env`.
- For code that uses a config, inject a config instance or stub the singleton method.
- Do not set `ENV` directly in tests.

## 9. Debug a wrong value

When a config value is not what you expect, do not guess. Ask the config where the value came from:

```sh
bin/rails runner 'pp StripeConfig.new'
```

```
#<StripeConfig
  config_name="stripe"
  env_prefix="STRIPE"
  values:
    currency => "eur" (type=env key=STRIPE_CURRENCY),
    api_key => "sk_test_..." (type=credentials store=config/credentials/development.yml.enc),
    webhook_secret => "whsec_..." (type=yml path=./config/stripe.yml)>
```

`StripeConfig.new.to_source_trace` returns the same data as a hash.
Use `.new`: the singleton keeps the values it loaded when the process started.
The output shows secrets in clear text. Do not copy it into commits, issues or reports.

If the trace does not explain the value, check these in order:

1. Priority: defaults → YAML (+ `.local.yml`) → credentials (+ local) → ENV → explicit values.
   A higher source wins, so a stale ENV variable hides a YAML change.
2. Names: `env_prefix` and `config_name` in the output. `FlyDeploy::Config` without
   `config_name` reads `FLYDEPLOY_*` and `config/flydeploy.yml`.
3. Environment: YAML with environment keys needs a section for the current `Rails.env`.
   Local files load in development only.
4. Typos: a misspelled key in YAML or credentials is ignored silently.
   Turn on `enforce_config_schema` to raise on unknown keys.
5. Types: ENV values are auto-cast (`"0123"` → `123`). The trace shows the raw string,
   the reader returns the cast value. Fix with `coerce_types key: :string`.

## 10. Gem features at a glance

The README documents each feature. `references/docs.md` maps tasks to README sections.

| Feature | Use it for |
|---|---|
| `attr_config`, `required`, `on_load`, `coerce_types` | Schema, validation, types |
| Local files (`*.local.yml`, local credentials) | Personal development overrides |
| `enforce_config_schema` (2.9+) | Raise or warn on unknown keys in YAML and credentials |
| Source tracing (`pp`, `to_source_trace`) | Find where a value came from |
| Generators (`anyway:install`, `anyway:config`) | New base class and config classes |
| `with_env` test helper | Set ENV in a block, with the Anyway ENV cache reset |
| Doppler, EJSON, custom loaders | More sources; ENV stays the last loader |
| `Anyway::Config.for(:name)` | Read a config without a class (prefer a class) |
| `to_rbs`, bundled signatures | Type-check configs with RBS and Steep |
| OptionParser integration | Build CLI options from a config (plain Ruby tools) |

## 11. Do not

- Do not read `ENV` or credentials outside config classes, except for infrastructure (§2).
- Do not commit secrets to `config/<name>.yml`. Development and test fakes are fine.
- Do not add a config class for one value that another config already covers.
- Do not mutate a config at runtime to change behavior. Pass a new instance instead.
- Do not reference a config from `app/configs/` or an in-place class during boot.
  Move it to `config/configs/`.
- Do not add an env-specific `if` to a config method when a YAML value can express the difference.

## 12. Report

When you finish, list:

- each config class you added or changed, and its location;
- each new parameter with its source (YAML, credentials, ENV) and its ENV variable name;
- the values that operators must set before a deployment (new required secrets);
- the direct `ENV` / credentials / `Rails.env` reads that you removed.
