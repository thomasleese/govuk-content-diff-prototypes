require 'diffy'
require 'hashdiff'

require_relative './sort_hash'

class CombinedDiff
  attr_reader :differences

  def initialize(a, b, sidebyside:)
    @a = a
    @b = b
    @sidebyside = sidebyside

    diff = HashDiff.best_diff(a, b)
    @differences = html_diff(combine_diff(diff))
  end

  private

  attr_reader :a, :b, :sidebyside

  def combine_diff(differences)
    all_fields = differences.map { |(_, field)| field }

    fields_to_combine = all_fields.select { |field| all_fields.count { |e| e == field } == 2 }.uniq

    fields_to_combine.each do |field|
      uncombined_differences = differences.select { |(_, f)| field == f }.sort { |a, b| a[0] <=> b[1] }
      differences.delete(uncombined_differences[0])
      differences.delete(uncombined_differences[1])
      new_difference = ['~', field, uncombined_differences[0][2], uncombined_differences[1][2]]
      differences.push(new_difference)
    end

    differences
  end

  def html_diff(differences)
    differences.map do |difference|
      if difference[0] == '~'
        if sidebyside
          left_and_right = Diffy::SplitDiff.new(difference[2], difference[3], format: :html)
          difference.push(left_and_right.left)
          difference.push(left_and_right.right)
        else
          difference.push(Diffy::Diff.new(difference[2], difference[3], include_plus_and_minus_in_html: true).to_s(:html))
        end
      else
        difference
      end
    end
  end
end
