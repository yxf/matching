module Matching
  class Config
    class << self
      attr_accessor :trade_executor
      attr_accessor :order_processor

      def init!
        @trade_executor = -> params { puts params }
        @order_processor = -> params { puts params }
      end
    end

    init!
  end
end