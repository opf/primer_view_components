# frozen_string_literal: true

module Primer
  module OpenProject
    class DataTable
      module Sorting
        ACTIVE_SORT_DIRECTIONS = %i[ASC DESC].freeze
        DEFAULT_SORT_DIRECTION = :ASC
        SORT_STRATEGIES = %i[basic datetime alphanumeric].freeze

        def self.normalize_strategy(sort_by)
          return nil if sort_by.nil? || sort_by == false
          return :basic if sort_by == true

          strategy = sort_by.to_sym if sort_by.respond_to?(:to_sym)

          if ACTIVE_SORT_DIRECTIONS.include?(strategy)
            raise ArgumentError, "`sort_by` selects a sort strategy. Use `initial_sort_direction` for sort direction."
          end

          return strategy if SORT_STRATEGIES.include?(strategy)

          raise ArgumentError, "`sort_by` must be true, false, nil, or one of: #{SORT_STRATEGIES.join(', ')}"
        end

        def self.normalize_direction(direction, default: DEFAULT_SORT_DIRECTION)
          return default if direction.nil?

          normalized = direction.to_sym if direction.respond_to?(:to_sym)
          return normalized if ACTIVE_SORT_DIRECTIONS.include?(normalized)

          raise ArgumentError, "`initial_sort_direction` must be one of: #{ACTIVE_SORT_DIRECTIONS.join(', ')}"
        end

        def self.sort_rows(rows, column:, direction:)
          rows.to_a.each_with_index.sort do |(row_a, index_a), (row_b, index_b)|
            result = compare_rows(row_a, row_b, column: column, direction: direction)
            result.zero? ? index_a <=> index_b : result
          end.map(&:first)
        end

        def self.compare_rows(row_a, row_b, column:, direction:)
          value_a = column.sort_value(row_a)
          value_b = column.sort_value(row_b)

          value_a_blank = blank_value?(value_a)
          value_b_blank = blank_value?(value_b)

          if !value_a_blank && !value_b_blank
            result = compare_values(value_a, value_b, column.sort_strategy)
            return direction == :ASC ? result : -result
          end

          return -1 unless value_a_blank
          return 1 unless value_b_blank

          0
        end

        def self.metadata_for(value, strategy)
          normalized_value = normalize_value(value, strategy)

          {
            blank: blank_value?(value),
            type: normalized_value.is_a?(Numeric) ? "number" : "text",
            value: normalized_value.to_s
          }
        end

        def self.compare_values(value_a, value_b, strategy)
          case strategy
          when :datetime
            datetime(value_a, value_b)
          when :alphanumeric
            alphanumeric(value_a.to_s, value_b.to_s)
          else
            basic(value_a, value_b)
          end
        end

        def self.basic(value_a, value_b)
          return 0 if value_a == value_b

          value_a < value_b ? -1 : 1
        rescue ArgumentError, NoMethodError
          value_a.to_s < value_b.to_s ? -1 : 1
        end

        def self.datetime(value_a, value_b)
          time_a = datetime_value(value_a)
          time_b = datetime_value(value_b)

          return 0 if time_a == time_b

          time_a > time_b ? 1 : -1
        end

        def self.alphanumeric(input_a, input_b)
          groups_a = alphanumeric_groups(input_a)
          groups_b = alphanumeric_groups(input_b)

          until groups_a.empty? || groups_b.empty?
            group_a = groups_a.shift
            group_b = groups_b.shift

            next if group_a == group_b

            if group_a.is_a?(String) && group_b.is_a?(String)
              result = group_a <=> group_b
              return result unless result.zero?
            elsif group_a.is_a?(Numeric) && group_b.is_a?(Numeric)
              return group_a > group_b ? 1 : -1
            elsif group_a.is_a?(Numeric) && group_b.is_a?(String)
              return -1
            elsif group_a.is_a?(String) && group_b.is_a?(Numeric)
              return 1
            end
          end

          return 0 if groups_a.length == groups_b.length

          groups_a.length > groups_b.length ? 1 : -1
        end

        def self.blank_value?(value)
          value.nil? || value == ""
        end

        def self.normalize_value(value, strategy)
          return "" if blank_value?(value)
          return datetime_value(value) if strategy == :datetime

          value
        end

        def self.datetime_value(value)
          case value
          when Time
            value.to_f
          when DateTime
            value.to_time.to_f
          when Date
            value.to_time.to_f
          else
            value
          end
        end

        def self.alphanumeric_groups(input)
          groups = []
          index = 0

          while index < input.length
            group = input[index]

            if numeric_character?(group)
              while index + 1 < input.length && numeric_character?(input[index + 1])
                index += 1
                group += input[index]
              end

              groups << group.to_i
            else
              while index + 1 < input.length && !numeric_character?(input[index + 1])
                index += 1
                group += input[index]
              end

              groups << group
            end

            index += 1
          end

          groups
        end

        def self.numeric_character?(value)
          value.match?(/[0-9]/)
        end
      end
    end
  end
end
