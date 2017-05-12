class DataLoader < Hash
  def initialize(directory)
    super

    Dir.glob("#{directory}/*/*/*.json") do |filename|
      parts = filename.split(File::SEPARATOR)
      document_type = parts[-3]
      content_id = parts[-2]
      version = parts[-1].split('.').first.to_i
      content = JSON.parse(File.read(filename))
      self[document_type] = {} unless key?(document_type)
      self[document_type][content_id] = [] unless self[document_type].key?(content_id)
      self[document_type][content_id][version] = content
    end
  end
end
