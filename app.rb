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

  def nice_field(text, content_item)
    fields = text.split(".")
    fields.map do |field|
      prefix = nil
      if field.end_with?("]")
        tokens = field.split("[")
        index = tokens.last.split("]").first.to_i
        prefix = (index + 1).ordinalize
        field = tokens.first

        if field == "parts"
          field = "#{content_item["details"]["parts"][index]["title"]} Part"
          prefix = nil
        end

        field = "route" if field == "routes"
        field = "available_translation" if field == "available_translations"
        field = "link" if field == "links"
        field = "expanded_link" if field == "expanded_links"
        field = "phone_number" if field == "phone_numbers"
        field = "organisation" if field == "organisations"
        field = "post_address" if field == "post_addresses"
      end

      field = field.gsub("_", " ").split.map(&:capitalize).join(' ').gsub("Id", "ID").gsub("Api", "API")

      next "#{prefix} #{field}" if prefix
      field
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

  if params[:style] == "changes"
    locals[:diff] = HashDiff.diff(content_a, content_b)
  elsif params[:style] == "inline"
    locals[:diff] = Diffy::Diff.new(YAML.dump(content_a), YAML.dump(content_b), include_plus_and_minus_in_html: true).to_s(:html)
  elsif params[:style] == "sidebyside"
    locals[:diff] = Diffy::SplitDiff.new(YAML.dump(content_a), YAML.dump(content_b), format: :html)
  elsif params[:style] == "combination"
    locals[:diff] = CombinedDiff.new(content_a, content_b, sidebyside: false)
  elsif params[:style] == "combinationsidebyside"
    locals[:diff] = CombinedDiff.new(content_a, content_b, sidebyside: true)
  end

  erb :layout, layout: false do
    erb :index, locals: locals do
      erb :"styles/#{params[:style]}", locals: locals
    end
  end
end
