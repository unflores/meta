$LOAD_PATH << File.expand_path(__dir__)
require 'ostruct'
require 'date'
require 'persistance/csv'

module Kpis

  # When we began tagging commits to define a deploy
  EARLIEST_DATE = Date.new(2019,8)

  Tag = Struct.new(:tag, :date, keyword_init: true)

  class Deploys

    def self.from_git_versions
      version_lines = %x(git log --tags --simplify-by-decoration --pretty="format:%ai %d"|grep tag).split("\n")
      new(version_lines)
    end

    DATA_PERSISTANCE_NAME = 'deploys'.freeze
    DATE_REGEX = /[0-9]{4}-[0-9]{2}-[0-9]{2}/.freeze

    attr_accessor :version_lines

    def initialize(version_lines, persistance = Persistance::Csv.new(DATA_PERSISTANCE_NAME))
      @version_lines = version_lines
      @persistance   = persistance
    end

    def create_deploys_per_month!
      @persistance.save(find_deploys_per_month)
    end

    def find_deploys_per_month
      tags = version_lines.map{ |version_raw| get_tag(version_raw) }
      tags.reduce(prime_dates_hash) do |hash, tag|
        key = "#{tag.date.year}-#{tag.date.month}"

        hash[key] ||= 0
        hash[key] += 1
        hash
      end
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

      # if a commit has multiple tags, just take the first, b/c there is only one valid deploy per commit
      tag = tags.first
      Tag.new(tag: tag, date: Date.parse(date))
    end

    # Use this string to represent the dates in the hash keys
    def key_from_date(date)
      "#{date.year}-#{date.month}"
    end

    # Fill the dates hash so that missing entries still have 0 deploys
    def prime_dates_hash
      current_date = EARLIEST_DATE
      dates = {}
      while current_date < Date.today
        dates[key_from_date(current_date)] = 0
        current_date = current_date.next_month
      end
      dates
    end

  end
end

# If called from command-line
if $PROGRAM_NAME == __FILE__
  puts Kpis::Deploys.from_git_versions.create_deploys_per_month!
end
