class CoolConfig < Anyway::Config # :nodoc:
  config_name :cool
  attr_config :meta,
              :data,
              port: 8080,
              host: 'localhost',
              user: { name: 'admin', password: 'admin' }
end
