require 'sinatra'

require_relative 'lib/data_loader'

data = DataLoader.new(File.join(File.dirname(__FILE__), 'data'))

get '/' do
  erb :index
end
