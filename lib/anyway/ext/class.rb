module Anyway
  module Ext
    # Extend String through refinements
    module Class
      refine ::Class do
        def underscore_name
          return unless name
          word = name[/^(\w+)/]
          word.gsub!(/([A-Z\d]+)([A-Z][a-z])/,'\1_\2')
          word.downcase!
          word
        end
      end
    end
  end
end
