module Matching
  class OrderBookManager

    attr_accessor :ask_order_book, :bid_order_book

    def self.build_order(attrs)
      attrs.symbolize_keys!

      raise ArgumentError, "Missing ord_type: #{attrs.inspect}" unless attrs[:ord_type].present?

      klass = ::Matching.const_get "#{attrs[:ord_type]}_order".camelize
      klass.new attrs
    end

    def initialize(market_id, options={})
      @market_id     = market_id
      @ask_order_book = OrderBook.new(market_id, :ask, options)
      @bid_order_book = OrderBook.new(market_id, :bid, options)
    end

    def get_books(type)
      case type
      when :ask
        [@ask_order_book, @bid_order_book]
      when :bid
        [@bid_order_book, @ask_order_book]
      end
    end

  end
end
