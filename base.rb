# Starting message
say %q{
      =============================================================
        load    template

}

# Clean up the Gemfile
run 'sed -e /#.*$/d -e /^\s*$/d -i Gemfile'
run %q{sed -e '/^gem /{x;p;x}' -e '/^group /{x;p;x}' -i Gemfile}

# Install third-party gems
append_file 'Gemfile', %q{ 
gem 'haml-rails', '~> 0.3.4'

group :development do
  gem 'hpricot', '0.8.6'
  gem 'ruby_parser', '2.3.1'
  gem 'pry', '~> 0.9.0'
end

group :development, :test do
  gem 'rspec-rails', '~> 2.11.0'
end

group :test do
  gem 'rb-inotify', '0.8.8'
  gem 'guard-rspec', '~> 1.2.1'
  gem 'guard-spork', '~> 1.2.0'
  gem 'factory_girl_rails', '~> 4.0.0'
  gem 'shoulda-matchers', '~> 1.3.0'
  gem 'forgery', '~> 0.5.0'
  gem 'capybara', '~> 1.1.2'
  gem 'database_cleaner', '~> 0.8.0'
  gem 'launchy', '~> 2.1.2'
end
}
Bundler.with_clean_env do
  run 'bundle install > /dev/null'
end

# Configure haml
inside 'app/views/layouts' do
  run 'bundle exec html2haml application.html.erb > application.html.haml'
  remove_file 'application.html.erb'
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
        routing_specs: false,
        controller_specs: true,
        request_specs: true
      g.fixture_replacement :factory_girl, dir: 'spec/factories'
    end
EOS
run 'sed 1d -i spec/spec_helper.rb'
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
gsub_file 'Guardfile', /:version => 2/, %q{:version => 2, cli: '-f d --drb', run_all: { cli: '-f p --drb' }, all_on_start: false, all_after_pass: false}
run %q<sed -e /^#.*$/d -e /^\s*$/d -e '/guard .*$/{x;p;x}' -i Guardfile>

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
  FactoryGirl.reload
end
EOS
end

# Creating databases
inside 'config' do
  run 'cp database.yml database.example'
  gsub_file 'database.yml', /(username:)\s*\w*$/, '\1 miro'
  gsub_file 'database.yml', /(password:)\s*$/, '\1 ' + "miro\n"
  run %q{sed -e /#.*$/d -e /^\s*$/d -e '/test:/{x;p;x}' -e '/production:/{x;p;x}' -i database.yml}
end
rake 'db:create', env: 'development'

# Clean up rails
remove_file 'public/index.html'
remove_file 'app/assets/images/rails.png'

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
}
