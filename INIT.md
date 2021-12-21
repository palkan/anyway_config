## Plan
1. Add option `current_environment` to __Anyway::Settings__ class. Provide default value for this, maybe `ENV["RAILS_ENV"]`?
2. Change method __Anyway::Loaders::YAML.call__. Add method `environmental?` and fetch all values from __Anyway::Settings.current_environment__ config file's section. Merge default values into resulting config keys.
3. Delete files __Rails::Loaders::YAML__ and its tests.
4. Add specs for environments in *spec/loaders/yaml_spec.rb*. Also add testcases for rails.
5. Extend rbs signature for `required`, `required_attributes` class methods of __Anyway::Config__.
6. Inside method `validate_required_attributes!` of __Anyway::Config__ class check if current key has option `env` and this env matches __Anyway::Settings.current_environment__ then raise validation error when key value is missed.

### Time
Work time: 7 hours  
Delivery date: 27.12.21
