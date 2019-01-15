module Matching
  class Engine
    DEFAULT_PRECISION = 8
    attr_accessor :order_book_manager

    def ask_order_book
      @order_book_manager.ask_order_book
    end

    def bid_order_book
      @order_book_manager.bid_order_book
    end

    # Matching::Engine.new('ethbtc')
    # options example:
    # { 
    #   id: ethbtc
    #   code: 1
    #   name: ETH/BTC
    #   base_unit: eth
    #   quote_unit: btc
    #   price_group_fixed: 3
    #   bid: {fee: 0.001, currency: btc, fixed: 8}
    #   ask: {fee: 0.001, currency: eth, fixed: 8}
    #   sort_order: 1
    # }
    def initialize(market_id, options={})
      @market_id    = market_id
      @order_book_manager    = OrderBookManager.new(market_id)
      @options = options
    end

    def submit(order)
      book, counter_book = @order_book_manager.get_books order.type
      match order, counter_book
      add_or_cancel order, book
    rescue
      Matching.logger.fatal "Failed to submit order #{order.label}: #{$!}"
      Matching.logger.fatal $!.backtrace.join("\n")
    end

    def cancel(order)
      book, counter_book = @order_book_manager.get_books order.type
      if removed_order = book.remove(order)
        publish_cancel removed_order, "cancelled_by_user"
      else
        # publish_cancel removed_order, "not_found"
        Matching.logger.warn "Skip: Cannot find order##{order.id} to cancel"
      end
    rescue
      Matching.logger.fatal "Failed to cancel order #{order.label}: #{$!}"
      Matching.logger.fatal $!.backtrace.join("\n")
    end

    def limit_orders
      { ask: ask_order_book.limit_orders,
        bid: bid_order_book.limit_orders }
    end

    def market_orders
      { ask: ask_order_book.market_orders,
        bid: bid_order_book.market_orders }
    end

    private

    def match(order, counter_book)
      return if order.filled?
      return if tiny?(order)

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
        book.add(order) : publish_cancel(order, "fill_or_kill") #fill or kill market order
    end

    def publish(order, counter_order, trade)
      ask, bid = order.type == :ask ? [order, counter_order] : [counter_order, order]

      price  = trade[0]
      volume = trade[1]
      funds  = trade[2]

      payload = {
        market: @market_id, 
        ask_id: ask.id, 
        bid_id: bid.id, 
        strike_price: price, 
        volume: volume, 
        funds: funds
      }
      Matching.order_traded && Matching.order_traded.call(payload)
    end

    def publish_cancel(order, reason)
      payload = {
        action: 'cancel', 
        order: order.attributes,
        reason: reason
      }
      Matching.order_canceled && Matching.order_canceled.call(payload)
    end

    # 检查委托数量时候小于最小精度
    def tiny?(order)
      fixed = @options['ask']['fixed'] || DEFAULT_PRECISION
      min_volume = '1'.to_d / (10 ** fixed)
      order.volume < min_volume
    end
  end
end
