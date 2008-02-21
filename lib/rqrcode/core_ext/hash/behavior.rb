module CoreExtensions
  module Hash
    module Behavior
      def stringify_keys
        inject({}) do |options, (key, value)|
          options[key.to_s] = value
          options
        end
      end
    end
  end
end
