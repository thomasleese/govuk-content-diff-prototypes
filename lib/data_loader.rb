class DataLoader < Hash
  def initialize(directory)
    super

    puts "#{directory}/*/*.json"

    Dir.glob("#{directory}/*/*.json") do |filename|
      parts = filename.split(File::SEPARATOR)
      content_id = parts[-2]
      version = parts[-1].split('.').first.to_i
      content = JSON.parse(File.read(filename))
      self[content_id] = [] unless key?(content_id)
      self[content_id][content["payload_version"] - 1] = content
    end
  end
end
