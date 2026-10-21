# Testing configuration

## Contents

1. Test values live in YAML
2. Test the config class
3. Test code that uses a config
4. ENV in tests
5. CI and asset precompilation

## 1. Test values live in YAML

Put deterministic values in the `test:` section of `config/<name>.yml`:

```yaml
# config/fly_deploy.yml
test:
  rest_api_url: http://localhost:3002/fake_fly
  api_token: test-token
  org_slug: test-org
```

- The test suite then needs no secrets and no credentials key.
- Integrations that use a `configured?` predicate stay off in test when their secrets are absent.
- Use obviously fake values (`test-token`, `sk_test_fake`). Never copy real secrets.

## 2. Test the config class

Test the logic that you added: predicates, derived values, adapters, validations.
Do not test that Anyway Config reads YAML.

Build an instance with explicit values. Other sources do not override them:

```ruby
# spec/configs/smtp_config_spec.rb
RSpec.describe SMTPConfig do
  subject(:config) { described_class.new(address: "smtp.example.com", port: 587, username: "u") }

  it { is_expected.to be_configured }

  specify do
    expect(config.to_settings).to include(address: "smtp.example.com", user_name: "u")
  end

  context "without address" do
    subject(:config) { described_class.new(address: nil) }

    it { is_expected.not_to be_configured }
  end
end
```

Check the ENV mapping and type coercion with `with_env`.
The helper is included automatically for specs in `spec/configs/` or with `type: :config`:

```ruby
RSpec.describe AnycableProConfig, type: :config do
  it "parses a comma-separated safelist" do
    with_env("ANYCABLE_PRO_GITHUB_SAFELIST" => "alice,bob") do
      expect(described_class.new.github_safelist).to eq(%w[alice bob])
    end
  end
end
```

`with_env` sets the variables, clears the Anyway ENV cache and restores both after the block.
Pass `nil` to delete a variable.
Elsewhere, require `"anyway/testing/helpers"` and include `Anyway::Testing::Helpers`
(this also works for Minitest).

Check `required` validations:

```ruby
it "requires the magic link key" do
  expect { described_class.new(magic_link_key: "") }
    .to raise_error(Anyway::Config::ValidationError, /magic_link_key/)
end
```

`required ..., env:` checks the environment once, when the class loads.
A stub in a test cannot change it, so do not test environment-scoped `required` in unit tests.

Check an environment-dependent default:

```ruby
it "enables analytics in production by default" do
  allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))

  expect(described_class.new(analytics_enabled: nil)).to be_analytics_enabled
end
```

## 3. Test code that uses a config

### Inject a config

If the class takes the config as an argument, pass an instance with explicit values.
This is the preferred way:

```ruby
let(:config) { FlyDeploy::Config.new(api_token: "t", rest_api_url: "http://fake") }
let(:client) { FlyDeploy::Client.new(config) }
```

### Stub the singleton

If the code calls the singleton (`AppConfig.cables_quota`), stub the class method.
`delegate_missing_to` defines `respond_to_missing?`, so verified partial doubles accept the stub:

```ruby
before { allow(AppConfig).to receive(:analytics_enabled?).and_return(true) }
```

Read expected values from the config instead of hard-coding them:

```ruby
expect(account.cables_quota).to eq(AppConfig.cables_quota)
```

### Do not mutate the singleton

Do not assign attributes on the shared instance (`AppConfig.cables_quota = 10`).
The value leaks into other tests. Stub the method or inject an instance.

## 4. ENV in tests

- The singleton loads once per process. `with_env` does not change it.
  Use `with_env` together with `described_class.new`, not with `AppConfig.some_value`.
- Do not assign `ENV[...]` directly. Anyway Config caches parsed ENV,
  and a missed restore leaks into other tests. Use `with_env`.
- A gem that reads `ENV` itself (for example, Pay) is outside Anyway Config.
  Set and restore its variable in an `around` hook.

## 5. CI and asset precompilation

- `bin/rails assets:precompile` with `SECRET_KEY_BASE_DUMMY=1` skips `required` validations.
- In other jobs without secrets, set `ANYWAY_SUPPRESS_VALIDATIONS=1`.
- Turn on `config.anyway_config.enforce_config_schema = true` so that the test suite
  fails on a mistyped key in YAML or credentials.
