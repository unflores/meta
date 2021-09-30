require 'csv'

module Persistance
  class Csv
    attr_accessor :storage_name

    CSV_PATH = File.join(
      File.expand_path(__dir__),
      '../data/__storage_name__.csv'
    ).freeze

    def initialize(storage_name)
      @storage_name = storage_name
    end

    def save(data)
      if data[:headers].nil?
        CSV.open(file_path, 'wb') do |csv|
          csv << data.keys
          csv << data.values
        end
      else

        CSV.open(file_path, 'wb') do |csv|
          headers = data.delete(:headers)
          headers.unshift('')
          csv << headers

          data.each do |key, values|
            csv << values.unshift(key)
          end
        end
      end
    end

    private

    def file_path
      CSV_PATH.gsub('__storage_name__', storage_name)
    end
  end
end
