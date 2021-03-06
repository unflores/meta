MAIN_BRANCH = 'master'.freeze

if `git rev-parse --abbrev-ref HEAD`.chomp != MAIN_BRANCH
  raise "Your branch is not #{MAIN_BRANCH}. Only do this on #{MAIN_BRANCH}"
end

class CheckoutFailure < StandardError; end

$LOAD_PATH << File.expand_path(__dir__)
require 'persistance/csv'
require 'byebug'

storage = Persistance::Csv.new('LOC')

commits =
  `git log --pretty=oneline --no-merges| awk -F" " '{print $1}'`.split("\n")

DATE_REGEX = /[0-9]{4}-[0-9]{2}-[0-9]{2}/.freeze

commits_backward = 0

loc_check = {
  ruby: "find #{Dir.pwd} -name '*.rb' | xargs wc -l",
  typescript: "find #{Dir.pwd}/app/javascript -name '*.ts*' | xargs wc -l",
  javascript: "find #{Dir.pwd}/app/javascript -name '*.js*' | xargs wc -l",
  # coffee* <- to also catch erb
  coffee: "find #{Dir.pwd}/app/assets/ -name '*.coffee*' | xargs wc -l"
}

rows = {
  headers: [],
  ruby: [],
  typescript: [],
  javascript: [],
  coffee: []
}

def checkout_commit(commit_hash)
  checkout_command = "git checkout #{commit_hash}"
  success = system(checkout_command)
  unless success
    raise CheckoutFailure, "Checkout failed with '#{checkout_command}'"
  end
end

begin
  while commits_backward <= commits.length
    checkout_commit(commits[commits_backward])

    loc_check.each do |key, finder|
      # wc -l returns multiple totals sometimes, ugh
      rows[key] << `#{finder}`.split("\n")
                              .filter { |count_line| count_line[/ total/] }
                              .map { |total_line| total_line[/[0-9]+/].to_i }
                              .sum
    end
    rows[:headers] << `git show -q --pretty="format:%ai"`[DATE_REGEX]

    commits_backward += 50
  end

  storage.save(rows)

  `git checkout #{MAIN_BRANCH}`
rescue Exception => e
  puts e.message
  puts e.backtrace
  puts "Failed hardcore, going back to #{MAIN_BRANCH} branch"
  `git checkout #{MAIN_BRANCH}`
end
