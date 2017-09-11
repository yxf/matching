module Matching
  class Config
    class << self
      attr_accessor :order_traded
      attr_accessor :order_canceled
      attr_accessor :order_book_changed

      def init!
        @order_traded = -> data { puts data }
        @order_canceled = -> data { puts data }
        @order_book_changed = -> data { puts data }
      end
    end

    init!
  end
end