# Organizing configuration in a Rails app

## Contents

1. Layers
2. File layout
3. Base class and access
4. Boot integration
5. Sources in practice
6. In-place config classes
7. Shared config names
8. Recommended settings

## 1. Layers

```
Application code (models, services, controllers, initializers)
        │ depends on
        ▼
Config classes (schema: names, defaults, types, validation, predicates)
        │ loaded from
        ▼
Sources (YAML, credentials, ENV, Doppler, EJSON, custom loaders)
```

Sources are infrastructure. You can move a value from YAML to credentials to ENV,
and the application code does not change.

## 2. File layout

```
config/
├── application.rb              # assigns configs to Rails.application.config
├── configs/                    # static configs: available at boot
│   ├── application_config.rb
│   ├── app_config.rb
│   ├── smtp_config.rb
│   └── stripe_config.rb
├── app.yml                     # non-secret values, per environment
├── smtp.yml
├── app.local.yml               # personal overrides (git-ignored)
└── credentials/
    ├── production.yml.enc      # secrets
    ├── development.yml.enc
    └── local.yml.enc           # personal secrets (git-ignored)
app/services/fly_deploy/
├── client.rb
└── config.rb                   # in-place config: FlyDeploy::Config
```

`config/configs/` is the default value of `config.anyway_config.autoload_static_config_path`.
Anyway Config autoloads it before the initializers run. Rails does not reload it in development.

`app/configs/` is a normal autoload path. Its classes reload in development,
but they are not available in `config/application.rb` or before the app finishes initialization.

Set `autoload_static_config_path = "app/configs"` to keep all configs in `app/configs/`.

### Custom inflections

Static configs load before `config/initializers/inflections.rb`.
If a class name needs an acronym (`SMTPConfig`), require the inflections first (README, issue #81):

```ruby
# config/application.rb
require_relative "boot"
require "rails/all"
require_relative "initializers/inflections"
```

## 3. Base class and access

The generator creates a singleton base class:

```ruby
class ApplicationConfig < Anyway::Config
  class << self
    delegate_missing_to :instance

    private

    def instance
      @instance ||= new
    end
  end
end
```

Callers write `StripeConfig.secret_key`. The instance loads once per process.

- Use the class methods in application code.
- Use `StripeConfig.new` when you need a fresh read (a script, a test, an initializer that must not
  keep the singleton).
- Use `StripeConfig.new(key: value)` to build a config with explicit values. Other sources do not
  override explicit values.

## 4. Boot integration

Expose the configs that Rails itself needs on `Rails.application.config`.
Then configure the framework from them in one place:

```ruby
# config/application.rb
module MyApp
  class Application < Rails::Application
    config.app = AppConfig
    config.mailer = MailerConfig
    config.smtp = SMTPConfig

    if config.app.host
      config.action_controller.default_url_options =
        config.action_mailer.default_url_options = {
          host: config.app.host,
          port: config.app.port,
          protocol: config.app.ssl? ? "https" : "http"
        }
      config.action_controller.asset_host = config.app.asset_host
    end

    config.action_mailer.default_options = config.mailer.to_default_options

    if config.smtp.configured?
      config.action_mailer.delivery_method = :smtp
      config.action_mailer.smtp_settings = config.smtp.to_settings
    end
  end
end
```

The config class owns the shape (`to_settings`, `to_default_options`).
`config/application.rb` only connects it to Rails.

### Initializers

Turn an integration on when its settings are present. Do not check the environment:

```ruby
# config/initializers/omniauth.rb
Rails.application.config.middleware.use OmniAuth::Builder do
  if GithubConfig.oauth_configured?
    provider :github, GithubConfig.oauth_key, GithubConfig.oauth_secret,
      scope: GithubConfig.oauth_scope
  end
end
```

```ruby
# config/initializers/litestream.rb
Rails.application.configure do
  litestream = LitestreamConfig.new
  next unless litestream.configured?

  config.litestream.replica_bucket = litestream.bucket
  config.litestream.replica_key_id = litestream.access_key_id
  config.litestream.replica_access_key = litestream.secret_access_key
end
```

### Gems that read only ENV

Copy the value from the config once, in the gem's initializer:

```ruby
# config/initializers/pay.rb
# Pay reads Stripe keys from ENV, but we keep them in StripeConfig
ENV["STRIPE_PRIVATE_KEY"] ||= StripeConfig.secret_key
```

### Routes

Configs can gate routes, too: `mount Litestream::Engine, at: "/litestream" if LitestreamConfig.configured?`.

## 5. Sources in practice

### YAML: non-secret values per environment

```yaml
# config/app.yml
default: &default
  host: localhost
  port: 3000

development:
  <<: *default

test:
  <<: *default
  port: 3002

production:
  host: example.com
  port: 443
```

- With `config.anyway_config.default_environmental_key = "default"`, Anyway Config deep-merges
  `default:` into each environment. Then you do not need YAML anchors.
- With `config.anyway_config.future.use :unwrap_known_environments`, a file without environment keys
  applies to all environments.
- A section can be absent. For example, `smtp.yml` can define `production:` only.
- Fake values for development and test belong here: a stub API URL, `api_token: "test-token"`.
- A production section that omits a secret makes `required` fail fast if the secret is missing
  from credentials and ENV.

### Credentials: secrets

```yaml
# bin/rails credentials:edit --environment production
stripe:
  secret_key: sk_live_...
  signing_secret: whsec_...
smtp:
  username: ...
  password: ...
```

The top-level key is the config name. The `stripe:` keys map to `StripeConfig` attributes.

### ENV: deployment-time values

`STRIPE_SECRET_KEY` sets `StripeConfig#secret_key`. ENV has the highest priority
of the standard sources, so an operator can override any value without a deploy.

- Nested keys use a double underscore: `APP_SMTP__PORT` → `app.smtp["port"]`.
- Values are auto-cast: `"true"` → `true`, `"42"` → `42`, `"a,b"` → `["a", "b"]`.
  Use `coerce_types` to change or fix the type.

### Local files: personal development overrides

`config/app.local.yml` (no environment keys) and `config/credentials/local.yml.enc`
load in development only. Use them for a personal token, a fork's repository name,
or a real API in place of the fake one. They must be git-ignored.

A local YAML file supports ERB. Use it to switch between a fake and a real service:

```yaml
# config/fly_deploy.local.yml
<% if ENV["REAL_FLY"] %>
rest_api_url: https://api.machines.dev/v1
org_slug: my-org
<% end %>
```

### Data that stays outside configs

- Process and infrastructure settings: `PORT`, `RAILS_MAX_THREADS`, `WEB_CONCURRENCY`,
  `DATABASE_URL`, `RAILS_LOG_LEVEL`. Rails, Puma and the database adapter read them directly.
- Values that a third-party binary reads from its own ENV variables.

## 6. In-place config classes

Put a config next to the code that uses it when only one module needs it.
This keeps a module (or a packwerk pack, or an engine) self-contained.

```ruby
# app/services/fly_deploy/client.rb
module FlyDeploy
  class Client
    attr_reader :config

    delegate :api_token, :rest_api_url, to: :config

    def initialize(config = FlyDeploy::Config)
      @config = config
    end
  end
end
```

- Set `config_name` explicitly. For `FlyDeploy::Config`, the inferred name is `flydeploy`.
- The class autoloads with the rest of `app/`. Do not use it in `config/application.rb` outside
  a `config.after_initialize` or `server do` block.
- If the module grows and boot code needs the config, move the class to `config/configs/`.

A config can also be nested inside the model that uses it:

```ruby
class License::GithubAccess
  class Config < ApplicationConfig
    config_name :github

    attr_config :token

    def enabled? = token.present?
  end

  def initialize(repo:, config: Config)
    @repo = repo
    @config = config
  end

  def grant(user)
    unless config.enabled?
      Rails.logger.warn("GitHub access is not configured")
      return
    end

    GithubClient.new(config.token).add_collaborator(@repo, user.github_login)
  end
end
```

## 7. Shared config names

Two classes can read the same config name. In the example above, `License::GithubAccess::Config`
and `GithubConfig` both read `config/github.yml`, `credentials.github` and `GITHUB_*`.
Each class sees only its own attributes.

With `enforce_config_schema` on, each class reports the other class's keys as unknown.
Allow them with `rescue_unknown_attributes_with`:

```ruby
Anyway::Settings.rescue_unknown_attributes_with = ->(config, _key) do
  config.config_name == "github"
end
```

## 8. Recommended settings

Put the settings at the top of the application class, before any config is referenced.
Settings in `config/environments/*.rb` apply too late for configs that `application.rb` already loaded.

```ruby
# config/application.rb
module MyApp
  class Application < Rails::Application
    # Deep-merge the `default:` section into each environment
    config.anyway_config.default_environmental_key = "default"
    # Pass all future features in a single `use` call: each call resets the list
    config.anyway_config.future.use :unwrap_known_environments, :reject_unknown_overrides
    # Raise on unknown keys in YAML and credentials (typos). Requires 2.9+. Use :warn to only log
    config.anyway_config.enforce_config_schema = true
    config.anyway_config.known_environments << "staging"

    config.app = AppConfig
    # ...
  end
end
```

Asset precompilation in CI or Docker runs without secrets. `required` validations skip
automatically when `SECRET_KEY_BASE_DUMMY` is set. Otherwise, set `ANYWAY_SUPPRESS_VALIDATIONS=1`.
