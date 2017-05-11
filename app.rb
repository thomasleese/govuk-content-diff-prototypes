require 'sinatra'

require_relative 'lib/data_loader'

data = DataLoader.new(File.join(File.dirname(__FILE__), 'data'))

get '/' do
  redirect "/#{data.keys.first}"
end

get '/:content_id' do
  erb :index, locals: { data: data }
end
