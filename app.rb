require 'active_support/core_ext/integer/inflections'
require 'diffy'
require 'hashdiff'
require 'sinatra'
require 'yaml'

require_relative 'lib/combined_diff'
require_relative 'lib/data_loader'
require_relative 'lib/sort_hash'

data = DataLoader.new(File.join(File.dirname(__FILE__), 'data'))

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end

  def nice_field(text)
    parts = text.split(".")
    parts.map do |part|
      if part.end_with?("]")
        tokens = part.split("[")
        number = tokens.last.split("]").first.to_i + 1
        part = "#{number.ordinalize} #{tokens.first.gsub('_', ' ').split.map(&:capitalize).join(' ').gsub("Id", "ID")}"
      else
        part.gsub("_", " ").split.map(&:capitalize).join(' ').gsub("Id", "ID")
      end
    end.join(" ➡ ")
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
  redirect "/#{params[:document_type]}/#{params[:content_id]}/#{params[:version_a]}/#{params[:version_b]}/changes"
end

get '/:document_type/:content_id/:version_a/:version_b/:style' do
  content_a = data[params[:document_type]][params[:content_id]][params[:version_a].to_i].sort_by_key(true)
  content_b = data[params[:document_type]][params[:content_id]][params[:version_b].to_i].sort_by_key(true)

  locals = {
    all_document_types: data.keys.sort,
    all_content_ids: data[params[:document_type]].keys.sort,
    versions: data[params[:document_type]][params[:content_id]].count,
    content_a: content_a,
    content_b: content_b,
  }

  if params[:style] == "changes"
    locals[:diff] = HashDiff.diff(content_a, content_b)
  elsif params[:style] == "inline"
    locals[:diff] = Diffy::Diff.new(YAML.dump(content_a), YAML.dump(content_b), include_plus_and_minus_in_html: true).to_s(:html)
  elsif params[:style] == "sidebyside"
    locals[:diff] = Diffy::SplitDiff.new(YAML.dump(content_a), YAML.dump(content_b), format: :html)
  elsif params[:style] == "combination"
    locals[:diff] = CombinedDiff.new(content_a, content_b)
  elsif params[:style] == "combinationsidebyside"
    locals[:diff] = CombinedDiff.new(content_a, content_b)
  end

  erb :layout, layout: false do
    erb :index, locals: locals do
      erb :"styles/#{params[:style]}", locals: locals
    end
  end
end
