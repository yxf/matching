require_relative 'config'
module Matching
  class Engine

    attr :orderbook, :mode, :queue

    def ask_orders
      @orderbook.ask_orders
    end

    def bid_orders
      @orderbook.bid_orders
    end

    # Matching::Engine.new('btccny')
    def initialize(market, options={})
      @market    = market
      @orderbook    = OrderBookManager.new(market)
    end

    def submit(order)
      book, counter_book = @orderbook.get_books order.type
      match order, counter_book
      add_or_cancel order, book
    rescue
      Rails.logger.fatal "Failed to submit order #{order.label}: #{$!}"
      Rails.logger.fatal $!.backtrace.join("\n")
    end

    def cancel(order)
      book, counter_book = orderbook.get_books order.type
      if removed_order = book.remove(order)
        publish_cancel removed_order, "cancelled by user"
      else
        Rails.logger.warn "Cannot find order##{order.id} to cancel, skip."
      end
    rescue
      Rails.logger.fatal "Failed to cancel order #{order.label}: #{$!}"
      Rails.logger.fatal $!.backtrace.join("\n")
    end

    def limit_orders
      { ask: ask_orders.limit_orders,
        bid: bid_orders.limit_orders }
    end

    def market_orders
      { ask: ask_orders.market_orders,
        bid: bid_orders.market_orders }
    end

    private

    def match(order, counter_book)
      return if order.filled?
      counter_order = counter_book.top
      return unless counter_order

      if trade = order.trade_with(counter_order, counter_book)

        counter_book.fill_top *trade
        order.fill *trade

        publish order, counter_order, trade

        match order, counter_book
      end
    end

    def add_or_cancel(order, book)
      return if order.filled?
      order.is_a?(LimitOrder) ?
        book.add(order) : publish_cancel(order, "fill or kill market order")
    end

    def publish(order, counter_order, trade)
      ask, bid = order.type == :ask ? [order, counter_order] : [counter_order, order]

      price  = trade[0]
      volume = trade[1]
      funds  = trade[2]

      Rails.logger.info "[#{@market}] new trade - ask: #{ask.label} bid: #{bid.label} price: #{price} volume: #{volume} funds: #{funds}"
      Config.trade_executor && Config.trade_executor.call({market: @market, ask_id: ask.id, bid_id: bid.id, strike_price: price, volume: volume, funds: funds})
    end

    def publish_cancel(order, reason)
      Rails.logger.info "[#{@market.id}] cancel order ##{order.id} - reason: #{reason}"
      Config.order_processor && Config.order_processor.call({action: 'cancel', order: order.attributes})
    end

  end
end
