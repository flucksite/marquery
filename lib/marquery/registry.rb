# frozen_string_literal: true

module Marquery
  module Registry
    @classes = []
    @mutex = Mutex.new

    class << self
      def classes
        @mutex.synchronize { @classes.dup }
      end

      def register(klass)
        @mutex.synchronize do
          @classes << klass unless @classes.include?(klass)
        end
      end

      def reset!
        @mutex.synchronize { @classes.clear }
      end
    end
  end
end
