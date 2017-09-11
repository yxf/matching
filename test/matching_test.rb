require "test_helper"
require "bigdecimal"
require "bigdecimal/util"
require "rbtree"
require_relative "../lib/matching/limit_order"
require_relative "../lib/matching/order_book_manager"
require_relative "../lib/matching/order_book"
require_relative "../lib/matching/engine"
require_relative "../test/amqp_mock"

# require_relative "../lib/matching/limit_order/"
class MatchingTest < Minitest::Test
  def setup
    # orderbook = Matching::OrderBookManager.new('btccny', broadcast: false)
    @subject = Matching::Engine.new('btccny', mode: :run)
    @price = 10.to_d
    @volume = 5.to_d
    @ask = Matching.mock_limit_order(type: :ask, price: @price, volume: @volume)
    @bid = Matching.mock_limit_order(type: :bid, price: @price, volume: @volume)
  end

  def test_that_it_has_a_version_number
    refute_nil ::Matching::VERSION
  end

  def test_fully_trade_limit_order
    @subject.submit(@ask)
    @subject.submit(@bid)

    assert_equal @subject.ask_orders.limit_orders.length, 0
    assert_equal @subject.bid_orders.limit_orders.length, 0
  end

  def test_partial_match_incoming_order_should_execute_trade
    @ask = Matching.mock_limit_order(type: :ask, price: @price, volume: 3.to_d)

    @subject.submit(@ask)
    @subject.submit(@bid)

    assert_empty@subject.ask_orders.limit_orders
    assert_equal @subject.bid_orders.limit_orders.length, 0

    @subject.cancel(@bid)
    assert_empty @subject.bid_orders.limit_orders
  end

  def test_match_order_with_many_counter_orders_should_execute_trade
    bid = Matching.mock_limit_order(type: :bid, price: @price, volume: 10.to_d)

    asks =
      [nil,nil,nil].map do
        Matching.mock_limit_order(type: :ask, price: @price, volume: 3.to_d)
      end

    asks.each {|ask| @subject.submit(ask) }
    @subject.submit(bid)

    assert_empty @subject.ask_orders.limit_orders
    assert_equal @subject.bid_orders.limit_orders.length, 0
  end

  def test_fully_match_order_after_some_cancellatons
    bid = Matching.mock_limit_order(type: :bid, price: @price,   volume: 10.to_d)
    low_ask = Matching.mock_limit_order(type: :ask, price: @price-1, volume: 3.to_d)
    high_ask = Matching.mock_limit_order(type: :ask, price: @price,   volume: 3.to_d)

    @subject.submit(low_ask) # low ask enters first
    @subject.submit(high_ask)
    @subject.cancel(low_ask) # but it's cancelled

    @subject.submit(bid)

    assert_empty @subject.ask_orders.limit_orders
    assert_equal @subject.bid_orders.limit_orders.length, 0
  end

  def test_should_cancel_order
    @subject.submit(@ask)
    @subject.cancel(@ask)
    assert_empty @subject.ask_orders.limit_orders

    @subject.submit(@bid)
    @subject.cancel(@bid)
    assert_empty @subject.bid_orders.limit_orders
  end

  def should_add_up_used_funds_to_locked_funds
    price = '3662.05'.to_d
    volume = '0.62'.to_d
    order = { market: 'btccny',
              type: :bid,
              ord_type: 'limit',
              volume: volume,
              price: price,
              locked: price * volume,
              timestamp: Time.now.to_i }

    bid  = Matching.mock_limit_order(order)

    ask1 = Matching.mock_limit_order(type: :ask, price: '3658.28'.to_d, volume: '0.0129'.to_d)
    ask2 = Matching.mock_limit_order(type: :ask, price: '3661.72'.to_d, volume: '0.26'.to_d)
    ask3 = Matching.mock_limit_order(type: :ask, price: '3659.00'.to_d, volume: '0.2945'.to_d)
    ask4 = Matching.mock_limit_order(type: :ask, price: '3661.68'.to_d, volume: '0.0526'.to_d)

    subject.submit bid
    subject.submit ask1
    subject.submit ask2
    subject.submit ask3
    subject.submit ask4


  end


end
