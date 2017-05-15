# Content Diff Prototypes

## Background

The objective is to build a number of prototypes which can be used to show diffs between versions of content items.

## Findings

### Technical Diffs

- Using a simple process described in [FieldNamer](lib/field_namer.rb), we can get very human readable field names.
- The [HashDiff][hashdiff] library can be used to create a diff between two editions.
- Using [Diffy][diffy] it is possible to produce clear govspeak diffs that are very readable.

### Non-technical Diffs

## Importing Data

```ruby
document_types = Edition.pluck(:document_type).uniq.sort
document_types.reject! { |d| d.start_with?("placeholder_") }
document_types.reject! { |d| d == "travel_advice_index" }
document_types.reject! { |d| d == "mainstream_browse_page" }
documents = document_types.map { |document_type| Edition.where(document_type: document_type, user_facing_version: 1).order('RANDOM()').limit(10).map(&:document).uniq }
documents.each { |docs| docs.each { |doc| doc.editions.order(user_facing_version: :asc).each_with_index { |edition, edition_index| json = Presenters::EditionPresenter.new(edition, draft: edition.draft?).for_content_store(0).to_json; dir = "data/#{doc.editions.first.document_type}/#{doc.content_id}"; FileUtils::mkdir_p(dir); File.write("#{dir}/#{edition_index}.json", json); nil } } }
```

[hashdiff]: https://github.com/liufengyun/hashdiff
[diffy]: https://github.com/samg/diffy
