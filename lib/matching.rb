require 'logger'
require 'matching/version'
require 'matching/constants'
require 'matching/limit_order'
require 'matching/market_order'
require 'matching/price_level'
require 'matching/order_book'
require 'matching/order_book_manager'
require 'matching/engine'

module Matching
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