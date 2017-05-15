require 'active_support/core_ext/integer/inflections'
require 'diffy'
require 'hashdiff'
require 'sinatra'
require 'yaml'

require_relative 'lib/combined_diff'
require_relative 'lib/data_loader'
require_relative 'lib/field_namer'
require_relative 'lib/sort_hash'

data = DataLoader.new(File.join(File.dirname(__FILE__), 'data'))

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end

  def human_field_name(text, content_item)
    FieldNamer.new(text, content_item).human_name
  end
end

get '/' do
  redirect "/#{data.keys.sort.first}"
end

get '/:document_type' do
  redirect "/#{params[:document_type]}/#{data[params[:document_type]].keys.sort.first}"
end

get '/:document_type/:content_id' do
  redirect "/#{params[:document_type]}/#{params[:content_id]}/0"
end

get '/:document_type/:content_id/:version_a' do
  redirect "/#{params[:document_type]}/#{params[:content_id]}/#{params[:version_a]}/0"
end

get '/:document_type/:content_id/:version_a/:version_b' do
  redirect "/#{params[:document_type]}/#{params[:content_id]}/#{params[:version_a]}/#{params[:version_b]}/technicalhashdiff"
end

get '/:document_type/:content_id/:version_a/:version_b/:view' do
  document = data[params[:document_type]][params[:content_id]]

  content_a = document[params[:version_a].to_i].sort_by_key(true)
  content_b = document[params[:version_b].to_i].sort_by_key(true)

  locals = {
    all_document_types: data.keys.sort,
    all_content_ids: data[params[:document_type]].keys.sort,
    versions: document.count,
    content_a: content_a,
    content_b: content_b,
  }

  if params[:view] == "technicalhashdiff"
    locals[:diff] = HashDiff.best_diff(content_a, content_b)
  elsif params[:view] == "technicalinline"
    locals[:diff] = Diffy::Diff.new(YAML.dump(content_a), YAML.dump(content_b), include_plus_and_minus_in_html: true).to_s(:html)
  elsif params[:view] == "technicalsidebyside"
    locals[:diff] = Diffy::SplitDiff.new(YAML.dump(content_a), YAML.dump(content_b), format: :html)
  elsif params[:view] == "technicalcombinationinline"
    locals[:diff] = CombinedDiff.new(content_a, content_b, sidebyside: false)
  elsif params[:view] == "technicalcombinationsidebyside"
    locals[:diff] = CombinedDiff.new(content_a, content_b, sidebyside: true)
  elsif params[:view] == "nontechnicalinline"
    locals[:diff] = CombinedDiff.new(content_a, content_b, sidebyside: false)
  elsif params[:view] == "nontechnicalsidebyside"
    locals[:diff] = CombinedDiff.new(content_a, content_b, sidebyside: true)
  end

  erb :layout, layout: false do
    erb :index, locals: locals do
      erb :"styles/#{params[:view]}", locals: locals
    end
  end
end
