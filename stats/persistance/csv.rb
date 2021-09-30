require 'csv'

module Persistance
  # The persistance class for writing to a CSV.
  # This file will take a hash with headers or without and write that to a csv
  class Csv
    attr_accessor :storage_name

    CSV_PATH = File.join(
      File.expand_path(__dir__),
      '../data/__storage_name__.csv'
    ).freeze

    def initialize(storage_name)
      @storage_name = storage_name
    end

    # @params [Hash] data that is being written
    # Ex. { headers: ['calls', 'ifs'], ruby: [1, 8]}
    def save(data)
      if data[:headers].nil?
        write(data)
      else
        write_with_headers(data)
      end
    end

    private

    def write(data)
      CSV.open(file_path, 'wb') do |csv|
        csv << data.keys
        csv << data.values
      end
    end

    def write_with_headers(data)
      CSV.open(file_path, 'wb') do |csv|
        headers = data.delete(:headers)
        headers.unshift('')
        csv << headers

        data.each do |key, values|
          csv << values.unshift(key)
        end
      end
    end

    def file_path
      CSV_PATH.gsub('__storage_name__', storage_name)
    end
  end
end
