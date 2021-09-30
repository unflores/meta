$LOAD_PATH << File.expand_path(__dir__)
require 'ostruct'
require 'date'
require 'persistance/csv'
require 'byebug'

module Kpis
  Tag = Struct.new(:tag, :date, keyword_init: true)

  class Deploys
    def self.from_git_versions
      version_lines_command = [
        'git log --tags --simplify-by-decoration --pretty="format:%ai %d"',
        'grep tag'
      ].join(' | ')

      version_lines = `#{version_lines_command}`.split("\n")
      new(version_lines)
    end

    DATA_PERSISTANCE_NAME = 'deploys'.freeze
    DATE_REGEX = /[0-9]{4}-[0-9]{2}-[0-9]{2}/.freeze

    attr_accessor :version_lines

    def initialize(
      version_lines,
      persistance = Persistance::Csv.new(DATA_PERSISTANCE_NAME)
    )
      @version_lines = version_lines
      @persistance   = persistance
    end

    def create_deploys_per_month!
      @persistance.save(find_deploys_per_month)
    end

    def find_deploys_per_month
      tags = version_lines.map { |version_raw| get_tag(version_raw) }
      deploys_per_month = tags.each_with_object({}) do |tag, hash|
        key = "#{tag.date.year}-#{tag.date.month}"

        hash[key] ||= 0
        hash[key] += 1
      end
      ascending(deploys_per_month)
    end

    # Takes a hash with YYYY-MM for keys and sorts the keys in ascending order
    # Hash of form {'2021-1' => 3}
    def ascending(month_hash)
      month_hash.map { |val| [parse_date(val[0]), val[1]] }
                .sort { |a, b| a <=> b }
                .map { |val| [stringify_date(val[0]), val[1]] }
                .to_h
    end

    # @params [String] date 'YYYY-MM'
    def parse_date(date)
      Date.new(*date.split('-').map(&:to_i))
    end

    # @params [Date] date
    # @returns 'YYYY-MM'
    def stringify_date(date)
      date.strftime('%Y-%m')
    end

    private

    # Expected format:
    # 2019-11-29 14:50:01 +0100  (tag: v3.3.1, tag: v3.3.0)
    # 2019-12-03 11:22:04 +0100  (tag: v3.3.2)
    # 2019-12-03 11:22:04 +0100  (tag: 3.300.2)
    # @returns [Tag] a tag for commit
    def get_tag(version_line)
      date = version_line[DATE_REGEX]
      tags = version_line.scan(/tag: v?(\d+\.\d+\.\d+)/).flatten

      # if a commit has multiple tags, just take the first,
      # b/c there is only one valid deploy per commit
      tag = tags.first
      Tag.new(tag: tag, date: Date.parse(date))
    end

    # Use this string to represent the dates in the hash keys
    def key_from_date(date)
      "#{date.year}-#{date.month}"
    end
  end
end

# If called from command-line
if $PROGRAM_NAME == __FILE__
  puts Kpis::Deploys.from_git_versions.create_deploys_per_month!
end
