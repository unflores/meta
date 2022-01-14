require 'byebug'
require 'pp'

$LOAD_PATH << File.expand_path(__dir__)

def check_file_knowledge(filename)
  run_command(
    <<-BASH
      git blame --line-porcelain #{filename}
        | sed -n 's/^author //p'
        | sort | uniq -c | sort -rn
    BASH
  )
end

def run_command(multi_line_string)
  `#{multi_line_string.gsub("\n", '')}`
end

def author_key(first, last)
  first = first.to_s.downcase
  last = last.to_s.downcase
  "#{first}_#{last}"
end

def transform_data(knowledge_data, author_knowledge)
  knowledge_data.split("\n").each do |raw_row|
    lines, first, last = raw_row.split(' ')
    if author_knowledge[author_key(first, last)].nil?
      author_knowledge[author_key(first, last)] = 0
    end
    author_knowledge[author_key(first, last)] += lines.to_i
  end

  author_knowledge
end

directory = ARGV.first

files = Dir["#{directory}**/*.*"]

author_knowledge = {}

files.each do |file|
  raw_file_data = check_file_knowledge(file)
  author_knowledge = transform_data(raw_file_data, author_knowledge)
end

author_knowledge.sort_by { |_key, value| -value }.each do |name, lines|
  puts "#{name}: #{lines}"
end
