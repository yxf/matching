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
  # Your code goes here...
end
