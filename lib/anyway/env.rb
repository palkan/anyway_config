module Anyway
  class Env

    # Regexp to detect array values
    # Array value is a values that contains at least one comma
    # and doesn't start/end with quote 

    ARRAY_RXP = /\A[^'"].*\s*,\s*.*[^'"]\z/

    def initialize
      @data = {}
      load
    end

    def reload
      clear
      load
      self
    end

    def clear
      @data.clear
      self
    end

    def method_missing(meth, *args, &block)
      meth = meth.to_s.gsub(/\_/,'')
      if args.empty? and @data.key?(meth)
        @data[meth]
      end
    end

    private
      def load
        ENV.each_pair do |key, val|
          if config_key?(key)
            mod, path = extract_module_path(key)
            set_by_path(get_hash(@data, mod), path, serialize_val(val))
          end
        end
      end
    
      def config_key?(key)
        key =~ /^[A-Z\d]+\_[A-Z\d\_]+/
      end

      def extract_module_path(key)
        _, mod, path = key.split(/^([^\_]+)/)
        path.sub!(/^[\_]+/,'')
        [mod.downcase, path.downcase]
      end

      def set_by_path(to, path, val)
        parts = path.split("__")

        while parts.length > 1
          to = get_hash(to, parts.shift)
        end
        to[parts.first] = val        
      end

      def get_hash(from, name)
        (from[name] ||= {}.with_indifferent_access)
      end

      def serialize_val(value)
        case value
        when ARRAY_RXP
          value.split(/\s*,\s*/).map(&method(:serialize_val))
        when /\A(true|t|yes|y)\z/i
          true
        when /\A(false|f|no|n)\z/i
          false
        when /\A(nil|null)\z/i
          nil
        when /\A\d+\z/
          value.to_i
        when /\A\d*\.\d+\z/
          value.to_f
        when /\A['"].*['"]\z/
          value.gsub(/(\A['"]|['"]\z)/,'')
        else
          value
        end
      end
  end
end