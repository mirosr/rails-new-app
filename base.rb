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
gem 'haml-rails', '~> 0.3.5'
gem 'hpricot', group: :development              #used by html2haml
gem 'ruby_parser', '2.3.1', group: :development #used by html2haml
}
Bundler.with_clean_env do
  run 'bundle install --quiet > /dev/null'
end

# Configure haml
inside 'app/views/layouts' do
  run 'bundle exec html2haml application.html.erb > application.html.haml'
  remove_file 'application.html.erb'
end
run 'sed "/, group: :development/d " -i Gemfile'
Bundler.with_clean_env do
  run 'bundle install --quiet > /dev/null'
end

# Configure sass
inject_into_file 'config/application.rb', <<-EOS, after: "config.assets.version = '1.0'\n"

    # Make use of sass syntax over scss
    config.sass.preferred_syntax = :sass
EOS

# Configure databases
inside 'config' do
  run 'cp database.yml database.example'
  gsub_file 'database.yml', /(username:)\s*\w*$/, '\1 miro'
  gsub_file 'database.yml', /(password:)\s*$/, '\1 ' + "miro\n"
  run %q{sed -e /#.*$/d -e /^\s*$/d -e '/test:/{x;p;x}' -e '/production:/{x;p;x}' -i database.yml}
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
