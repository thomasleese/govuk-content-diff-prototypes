require 'diffy'
require 'hashdiff'

require_relative './field_namer'
require_relative './htmlprosediff'

class CombinedDiff
  attr_reader :differences

  def initialize(a, b, options = {})
    @content_a = a
    @content_b = b
    @options = options

    diff = HashDiff.best_diff(a, b)

    @differences = html_diff(
      apply_readable_fields(
        apply_formatting(
          expand_diff(
            combine_diff(
              filter_fields(diff)
            )
          )
        )
      )
    )
  end

  private

  attr_reader :content_a, :content_b, :options

  HIDDEN_FIELDS = %w(
    rendering_app
    public_updated_at
    format
    schema_name
    document_type
    details.max_cache_time
    details.publishing_request_id
    details.country.synonyms
    details.email_signup_link
  )

  IMAGE_FIELDS = %w(
    details.image.url
  )

  def show_sidebyside?
    options.fetch(:sidebyside, false)
  end

  def use_prose_diff?
    options.fetch(:prose, false)
  end

  def make_fields_readable?
    options.fetch(:readable_fields, true)
  end

  def filter_fields(differences)
    return differences unless use_prose_diff?

    differences.select do |(_, field)|
      next false if HIDDEN_FIELDS.include?(field)
      next false if field.start_with?("routes")
      true
    end
  end

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

  def expand_diff(differences)
    differences.map do |difference|
      next [difference] if difference[1] == "~"

      if difference[2].is_a?(Array)
        expand_diff(difference[2].each_with_index.map do |thing, i|
          [difference[0], difference[1] + "[#{i}]", thing]
        end)
      elsif difference[2].is_a?(Hash)
        expand_diff(difference[2].map do |key, value|
          [difference[0], difference[1] + ".#{key}", value]
        end)
      else
        [difference]
      end
    end.flatten(1)
  end

  def apply_formatting(differences)
    return differences unless use_prose_diff?

    differences.map do |difference|
      field = difference[1]
      difference.each_with_index.map do |column, index|
        next column if index < 2

        if IMAGE_FIELDS.include?(field)
          "<img src=\"#{column}\" />"
        else
          Govspeak::Document.new(column.to_s).to_html
        end
      end
    end
  end

  def apply_readable_fields(differences)
    return differences unless make_fields_readable?
    differences.map do |difference|
      content_item = difference[0] == '-' ? content_a : content_b
      difference[1] = FieldNamer.new(difference[1], content_item).readable_name
      difference
    end
  end

  def html_diff(differences)
    differences.map do |difference|
      if difference[0] == '~'
        left = difference[2]
        right = difference[3]
      elsif difference[0] == '+'
        left = ''
        right = difference[2]
      else
        left = difference[2]
        right = ''
      end

      if show_sidebyside?
        if use_prose_diff?
          left_and_right = HtmlProseDiff.new(left, right)
          difference.push(left_and_right.diff)
          difference.push(left_and_right.diff)
        else
          left_and_right = Diffy::SplitDiff.new(left, right, format: :html)
          difference.push(left_and_right.left)
          difference.push(left_and_right.right)
        end
      else
        if use_prose_diff?
          difference.push(HtmlProseDiff.new(left, right).diff)
        else
          difference.push(Diffy::Diff.new(left, right, include_plus_and_minus_in_html: true).to_s(:html))
        end
      end

      difference
    end
  end
end
