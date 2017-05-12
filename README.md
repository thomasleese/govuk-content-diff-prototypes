# Content History Technical Diff Prototype

## Background

The objective is to build a prototype which can be used to show diffs between versions of content items, it is assumed that the audience of these are technical and thus are happy with diffs that reveal underlying things (such as json, line numbers, govspeak/html). The diffs will be inspired by how github diffs source code.

The prototype will have to:

- Find a way to access a variety of versions of content-items (maybe we export a bunch from Publishing API to JSON files)
- Utilise some sort of diffing library to show items
- Find ways to make the output as usable as possible
  - This might require deciding which fields should be shown for a particular document_type
  - Find ways to break up strings which have new lines in them (might mean using a different data format to JSON?

## Findings

-

## Technical Details

### To Import Data

```ruby
document_types = Edition.pluck(:document_type).uniq.sort
document_types.reject! { |d| d.start_with?("placeholder_") }
document_types.reject! { |d| d == "travel_advice_index" }
document_types.reject! { |d| d == "mainstream_browse_page" }
documents = document_types.map { |document_type| Edition.where(document_type: document_type, user_facing_version: 1).order('RANDOM()').limit(10).map(&:document).uniq }
documents.each { |docs| docs.each { |doc| doc.editions.order(user_facing_version: :asc).each_with_index { |edition, edition_index| json = Presenters::EditionPresenter.new(edition, draft: edition.draft?).for_content_store(0).to_json; dir = "data/#{doc.editions.first.document_type}/#{doc.content_id}"; FileUtils::mkdir_p(dir); File.write("#{dir}/#{edition_index}.json", json); nil } } }
```
