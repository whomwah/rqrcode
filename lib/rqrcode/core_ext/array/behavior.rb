module CoreExtensions
  module Array
    module Behavior
			def extract_options!
				last.is_a?(::Hash) ? pop : {}
			end
		end
	end
end
