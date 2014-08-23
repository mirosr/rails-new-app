# Starting message
say %q{
      =============================================================
        load    template

}

# Clean up the Gemfile
gsub_file 'Gemfile', /#.*\n/, ''
gsub_file 'Gemfile', /^\s*\n/, ''
gsub_file 'Gemfile', /^(gem|group )/, "\n\\1"

# Install third-party gems
append_file 'Gemfile', %q{
gem 'haml-rails', '~> 0.3.5'

group :development do
  gem 'hpricot'              #used by html2haml
  gem 'ruby_parser', '2.3.1' #used by html2haml
  gem 'pry', '~> 0.9.11'
end

group :development, :test do
  gem 'rspec-rails', '~> 2.12.2'
end

group :test do
  gem 'rb-inotify', '~> 0.8.8'
  gem 'guard-rspec', '~> 2.4.0'
  gem 'guard-spork', '~> 1.4.1'
  gem 'factory_girl_rails', '~> 4.2.0'
  gem 'shoulda-matchers', '~> 1.4.2'
  gem 'forgery', '~> 0.5.0'
  gem 'capybara', '~> 2.0.2'
  gem 'database_cleaner', '~> 0.9.1'
  gem 'launchy', '~> 2.1.2'
end
}
Bundler.with_clean_env do
  run 'bundle install --quiet > /dev/null'
end

# Configure haml
inside 'app/views/layouts' do
  run 'bundle exec html2haml application.html.erb > application.html.haml'
  remove_file 'application.html.erb'
end
gsub_file 'Gemfile', /^.*used by html2haml\n/, ''
Bundler.with_clean_env do
  run 'bundle install --quiet > /dev/null'
end

# Configure sass
inject_into_file 'config/application.rb', <<-EOS, after: "config.assets.version = '1.0'\n"

    # Make use of sass syntax over scss
    config.sass.preferred_syntax = :sass
EOS

# Configure rspec
generate 'rspec:install'
inject_into_file 'config/application.rb', <<-EOS, after: "config.sass.preferred_syntax = :sass\n"

    # Configure generators to use third-party gems
    config.generators do |g|
      g.test_framework :rspec,
        fixtures: true,
        view_specs: false,
        helper_specs: false,
        routing_specs: true,
        controller_specs: true,
        request_specs: true
      g.fixture_replacement :factory_girl, dir: 'spec/factories'
    end
EOS
inject_into_file 'spec/spec_helper.rb', <<-EOS, after: %|config.order = "random"\n|

  # Declare an inclusion filter named focus
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
EOS
inject_into_file 'spec/spec_helper.rb', <<-EOS, after: %|config.order = "random"\n|
  
  # Enable only the new expect syntax
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
EOS

# Configure capybara
inject_into_file 'spec/spec_helper.rb', "\nrequire 'capybara/rspec'", after: "require 'rspec/autorun'"

# Configure factory_girl
inject_into_file 'spec/spec_helper.rb', <<-EOS, after: %|config.run_all_when_everything_filtered = true\n|

  # Include factory_girl syntax to simplify factories calls
  config.include FactoryGirl::Syntax::Methods
EOS

# Configure guard
run 'bundle exec guard init -b 2> /dev/null'
append_file 'Guardfile', 'notification :off'
run 'bundle exec guard init spork 2> /dev/null'
run 'bundle exec guard init rspec 2> /dev/null'
gsub_file 'Guardfile', / :cucumber_env => \{.*\},/, ''
gsub_file 'Guardfile', /^\s*watch.* { :test_unit }$/, ''
gsub_file 'Guardfile', /^\s*watch.* { :cucumber }$/, ''
gsub_file 'Guardfile', /rspec'/, %q{rspec', cli: '-f d --drb', run_all: { cli: '-f p --drb' }, all_on_start: false, all_after_pass: false}
gsub_file 'Guardfile', /#.*\n/, ''
gsub_file 'Guardfile', /^\s*\n/, ''
gsub_file 'Guardfile', /^(guard )/, "\n\\1"

# Configure spork
inside 'spec' do
  gsub_file 'spec_helper.rb', /^/, '  '
  prepend_file 'spec_helper.rb', <<-EOS
require 'rubygems'
require 'spork'

Spork.prefork do
EOS
  append_file 'spec_helper.rb', <<-EOS
end

Spork.each_run do
  load "\#{Rails.root}/config/routes.rb"
  FactoryGirl.reload
end
EOS
end

# Configure databases
inside 'config' do
  run 'cp database.yml database.example'
  gsub_file 'database.yml', /#.*\n/, ''
  gsub_file 'database.yml', /^\s*\n/, ''
  gsub_file 'database.yml', /(username:)\s*\w*$/, '\1 miro'
  gsub_file 'database.yml', /(password:)\s*$/, "\\1 miro\n"
  gsub_file 'database.yml', /^(test: )/, "\n\\1"
  gsub_file 'database.yml', /^(production: )/, "\n\\1"
end

# Clean up rails
remove_file 'public/index.html'
remove_file 'app/assets/images/rails.png'
remove_file 'README.rdoc'

# Git
append_file '.gitignore', %q{
# Ignore gems managed by bundler
/vendor/bundle

# Ignore local database config file
/config/database.yml
}
git init: '-q'
git add: '.'
git commit: '-aqm "initial commit"'

# Ending message
say %q{
        done    loading template
      =============================================================

Hint: You should create the application's database manually with rake db:create
}
