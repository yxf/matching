$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "matching"

require "minitest/autorun"

module Matching

  class <<self
    @@mock_order_id = 10000

    def mock_limit_order(attrs)
      @@mock_order_id += 1
      Matching::LimitOrder.new({
                                   id: @@mock_order_id,
                                   timestamp: Time.now.to_i,
                                   volume: 1+rand(10),
                                   price: 3000+rand(3000),
                                   market_id: 'btccny'
                               }.merge(attrs))
    end

  end

end


