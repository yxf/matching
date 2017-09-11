module Matching
  class Config
    class << self
      attr_accessor :trade_executor
      attr_accessor :order_canceled
      attr_accessor :order_book_changed

      def init!
        @trade_executor = -> params { puts params }
        @order_canceled = -> params { puts params }
        @order_book_changed = -> params { puts params }
      end
    end

    init!
  end
end