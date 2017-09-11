require "matching/version"
require "logger"

begin
  Required::Module::const_get "Rails"
rescue NameError
  module Rails
    # @@logger = Logger.new('./log.log', 'daily')
    @@logger = Logger.new($stdout)
    def self.logger
      @@logger
    end
  end
end

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