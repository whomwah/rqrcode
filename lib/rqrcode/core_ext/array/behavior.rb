module CoreExtensions #:nodoc:
  module Array #:nodoc:
    module Behavior
      def extract_options!
        last.is_a?(::Hash) ? pop : {}
      end
    end
  end
end
