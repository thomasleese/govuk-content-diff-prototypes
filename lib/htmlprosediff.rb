require 'tempfile'

class HtmlProseDiff
  def initialize(left, right)
    @left = left
    @right = right

    @left_file = Tempfile.new('left')
    @left_file.write(left)
    @left_file.close

    @right_file = Tempfile.new('right')
    @right_file.write(right)
    @right_file.close
  end

  def diff
    %x(bin/htmldiff.pl #{@left_file.path} #{@right_file.path})
  end
end
