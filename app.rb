require 'sinatra'

require_relative 'lib/data_loader'

data = DataLoader.new(File.join(File.dirname(__FILE__), 'data'))

get '/' do
  redirect "/#{data.keys.first}"
end

get '/:content_id' do
  redirect "/#{params[:content_id]}/0"
end

get '/:content_id/:version_a' do
  redirect "/#{params[:content_id]}/#{params[:version_a]}/0"
end

get '/:content_id/:version_a/:version_b' do
  erb :index, locals: {
    data: data,
    all_content_ids: data.keys,
    versions: data[params[:content_id]].count,
    content_a: data[params[:content_id]][params[:version_a].to_i],
    content_b: data[params[:content_id]][params[:version_b].to_i],
  }
end
