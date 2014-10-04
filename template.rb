# Booster template.rb
# Launch Academy Holdings, Inc.'s Rails Template
# from Dan Pickett
# based on Suspenders by Thoughtbot
# influenced by Mike Gunderloy's rails template - http://gist.github.com/145676

require 'open-uri'
require 'yaml'
require 'base64'
require 'fileutils'
require 'active_support/inflector'
require 'active_support/core_ext/string/inflections'

def self.prepend_to_file(path, string)
  Tempfile.open File.basename(path) do |tempfile|
    # prepend data to tempfile
    tempfile << string

    File.open(path, 'r+') do |file|
      # append original data to tempfile
      tempfile << file.read
      # reset file positions
      file.pos = tempfile.pos = 0
      # copy all data back to original file
      file << tempfile.read
    end
  end
end

def download(from, to = from.split("/").last)
  run "curl -s -L #{from} > #{to}"
  # file to, open(from).read
rescue
  puts "Can't get #{from} - Internet down?"
  exit!
end

def from_repo(github_user, project_name, from, to = from.split("/").last)
  download("http://github.com/#{github_user}/#{project_name}/raw/master/#{from}", to)
end

gem 'kaminari'
gem 'slugged'

gem 'simple_form'
gem 'erubis'
gem 'airbrake'
gem 'configatron'
gem 'bourbon'
gem 'tab_menu'

gem 'bower-rails'

gem_group :development do
  gem 'rspec-rails'

  gem 'guard'
  gem 'guard-livereload'
  gem 'guard-rspec'
  gem 'guard-bundler'
  gem 'guard-konacha'
  gem 'konacha'

  gem 'rb-fsevent'
  gem 'growl'

  gem 'poltergeist',
    git: 'https://github.com/jonleighton/poltergeist.git'

  gem 'spring'
  gem 'dotenv-rails'
end

gem_group :test do
  gem 'rspec-rails'
  gem 'mocha'
  gem 'bourne'
  gem 'factory_girl_rails'
  gem 'valid_attribute'
  gem 'shoulda'
  gem "capybara"
  gem 'database_cleaner'
  gem 'launchy'
  # Pretty printed test output
  gem 'fuubar'
end

gem_group :development, :test do
  gem 'pry-rails'
  gem 'quiet_assets'
end

gem_group :production do
  gem 'rails_12factor'
end

run 'bundle install'

generate("rspec:install")
file '.rspec',
%q{
  --colour
  --format Fuubar
}, force: true

file 'spec/support/database_cleaner_helper.rb',
%q{RSpec.configure do |config|

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

end
}


generate(:airbrake, '--api-key abcdefg123456')
generate('responders:install')

#====================
# APP
#====================

file 'app/helpers/application_helper.rb',
%q{module ApplicationHelper
  def body_class
    "#{controller.controller_name} #{controller.controller_name}-#{controller.action_name}"
  end
end
}, :force => true

file 'app/views/layouts/_flashes.html.erb',
%q{<div class="l-flashes">
  <% flash.each do |key, value| -%>
    <div class="flash flash-<%= key %>"><%=h value %></div>
  <% end %>
</div>
}

file 'app/assets/javascripts/application.js',
%q{// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require xhr_fix
//= require_tree .

}, force: true

run 'mv app/assets/stylesheets/application.css app/assets/stylesheets/application.css.scss'
file 'app/assets/stylesheets/application.css.scss',
%q{/*
 * This is a manifest file that'll be compiled into application.css, which will include all the files
 * listed below.
 *
 * Any CSS and SCSS file within this directory, lib/assets/stylesheets, vendor/assets/stylesheets,
 * or vendor/assets/stylesheets of plugins, if any, can be referenced here using a relative path.
 *
 * You're free to add application-wide styles to this file and they'll appear at the top of the
 * compiled file, but it's generally better to create a new file per style scope.
 *
*/

@import 'foundation/css/normalize';
@import 'foundation/css/foundation';

@import 'font-awesome/scss/font-awesome';
@import 'fa_fix';

// Thoughtbot's Bourbon Mixins
@import "bourbon";
}, force: true

file 'app/assets/stylesheets/fa_fix.css.scss.erb',
%q{
/* FONT PATH: we have to hack this due to sprockets awesomeness
 * -------------------------- */
@font-face {
  font-family: 'FontAwesome';
  src: font-url('<%= asset_path 'font-awesome/fonts/fontawesome-webfont.eot' %>');
  src: font-url('<%= asset_path 'font-awesome/fonts/fontawesome-webfont.eot' %>?#iefix') format('embedded-opentype'),
    font-url('<%= asset_path 'font-awesome/fonts/fontawesome-webfont.woff' %>?v=#{$fa-version}') format('woff'),
    font-url('<%= asset_path 'font-awesome/fonts/fontawesome-webfont.ttf' %>?v=#{$fa-version}') format('truetype'),
    font-url('<%= asset_path 'font-awesome/fonts/fontawesome-webfont.svg' %>?v=#{$fa-version}#fontawesomeregular') format('svg');
  //src: url('#{$fa-font-path}/FontAwesome.otf') format('opentype'); // used when developing fonts
  font-weight: normal;
  font-style: normal;
}
}

initializer 'font_awesome.rb',
%q{
Rails.application.config.assets.precompile << 'font-awesome/fonts/*'
}

file 'app/views/layouts/application.html.erb',
%q{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
  <head>
    <meta http-equiv="Content-type" content="text/html; charset=utf-8" />

    <title><%= yield(:title) %></title>

    <meta name="description" content="<%= yield(:description) || "PROJECT DESCRIPTION" %>" />
    <meta name="keywords" content="<%= yield(:keywords) || "PROJECT KEYWORDS" %>" />
    <%= csrf_meta_tag %>

    <%= stylesheet_link_tag "application" %>

    <%= yield :extra_header %>
  </head>
  <body class="<%= body_class %>">
    <%= render :partial => 'layouts/flashes' -%>
    <%= yield %>

    <%= javascript_include_tag 'application' %>

    <%= yield :extra_footer %>
  </body>
</html>
}, :force => true

#====================
# INITIALIZERS
#====================

initializer 'smtp.rb',
%q{ActionMailer::Base.smtp_settings = {
    :address => "",
    :port    => 25,
    :domain  => ""
}
}

initializer 'konacha.rb',
%q{if defined?(Konacha)
  require 'capybara/poltergeist'
  Konacha.configure do |config|
    config.spec_dir     = 'spec/javascripts'
    config.spec_matcher = /_spec\.|_test\./
    config.driver       = :poltergeist
    config.stylesheets  = %w(application)
  end
end
}

initializer 'hosts.rb',
%q{configatron.default_host = {
  :development => "localhost:3000",
  :test => "localhost:3000",
  :production => "appname.com",
  :staging => "staging.appname.com"
}[Rails.env.to_sym]

ActionMailer::Base.default_url_options[:host] = configatron.default_host
Rails.application.routes.default_url_options[:host] = configatron.default_host
}

initializer 'errors.rb',
%q{# Example:
#   begin
#     some http call
#   rescue *HTTP_ERRORS => error
#     notify_hoptoad error
#   end

HTTP_ERRORS = [Timeout::Error,
               Errno::EINVAL,
               Errno::ECONNRESET,
               EOFError,
               Net::HTTPBadResponse,
               Net::HTTPHeaderSyntaxError,
               Net::ProtocolError]
}

initializer 'time_formats.rb',
%q{# Example time formats
{ :short_date => "%x", :long_date => "%a, %b %d, %Y" }.each do |k, v|
  Time::DATE_FORMATS.update(k => v)
  Date::DATE_FORMATS.update(k => v)
end
}

initializer 'validation_fix.rb',
%q{ActionView::Base.field_error_proc = Proc.new { |html_tag, instance|
  "<span class=\"fieldWithErrors\">#{html_tag}</span>".html_safe }
}

initializer 'tab_menu.rb',
%q{TabMenu.configure do |config|
  config.active_class = "active"
end

}

# ====================
# CONFIG
# ====================

capify!


# ====================
# TEST
# ====================

inside('spec') do
  run "mkdir support"
  ::FileUtils.touch("support/factories.rb")
end

file 'spec/javascripts/spec_helper.js.coffee',
%q{
  #= require 'application'

  Konacha.mochaOptions.ignoreLeaks = true

  beforeEach ->
    @page = $('#konacha')

}

file 'app/assets/javascripts/xhr_fix.js',
%q{jQuery.ajaxSetup({
  'beforeSend': function(xhr) {xhr.setRequestHeader("Accept",
    "text/javascript")}
});
}

file 'spec/spec_helper.rb',
%q{require 'rubygems'

ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)

require 'pry'

require 'mocha/setup'

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :mocha

  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
end
}, :force => true

file 'spec/rails_helper.rb',
%q{
# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require 'spec_helper'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

require 'factory_girl'
require 'database_cleaner'

require 'shoulda'
require 'capybara/rspec'
require 'valid_attribute'

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!
end
}

# ==============
# Simpleform
# ==============

generate('simple_form:install')

# ==============
# JS
# ==============

file 'app/assets/javascripts/xhr_fix.js',
%q{jQuery.ajaxSetup({
  'beforeSend': function(xhr) {xhr.setRequestHeader("Accept",
    "text/javascript")}
});
}

run("mkdir -p spec/javascripts/support")
download("http://sinonjs.org/releases/sinon-1.3.2.js", "spec/javascripts/support/sinon.js")

[
  "helpers",
  "models",
  "collections",
  "routers",
  "views",
  "templates"
].each do |js_dir|
  run("mkdir app/assets/javascripts/#{js_dir}")
  run("touch app/assets/javascripts/#{js_dir}/.gitkeep")
end

file('script/cibuild',
%q{#!/bin/bash

run_build(){
  source ~/.rvm/scripts/rvm
  PATH="$PATH:/usr/local/bin"
  export CI=true
  gem install bundler
  bundle
  cp -n config/database.example.yml config/database.yml
  bundle exec rake db:drop db:create db:migrate
  bundle exec rake db:drop db:create db:migrate RAILS_ENV=test
  rake
}

clean_up(){
  #clean up
  rm -f log/test.log && rm -rf public/system/tmp && rm -rf public/uploads/tmp && rm -rf tmp/*
}

run_build
build_result=$?
clean_up

exit $build_result
})

file('bin/stage',
%q{#!/bin/bash

echo "Deploy to staging!"
git checkout staging && git merge master && git pull origin staging && git push origin staging && git push staging staging:master
echo "Migrating..."
heroku run rake db:migrate -a $staging_app_name
echo "Deploy Complete"
git checkout master
})

file('bin/production',
%q{#!/bin/bash

echo "Deploy to production!"
git checkout production && git merge staging && git pull origin production && git push origin production && git push production production:master
echo "Migrating..."
heroku run rake db:migrate -a $production_app_name
echo "Deploy Complete"
git checkout master
})

# ===========
# GUARD
# ===========
file 'Guardfile', %q{
  # A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'bundler' do
  watch('Gemfile')
  # Uncomment next line if Gemfile contain `gemspec' command
  # watch(/^.+\.gemspec/)
end

### Guard::Konacha
#  available options:
#  - :spec_dir, defaults to 'spec/javascripts'
#  - :driver, defaults to :selenium

require 'capybara/poltergeist'
guard :konacha,
  driver: :poltergeist do

  watch(%r{^app/assets/javascripts/(.*)\.js(\.coffee)?$}) { |m| "#{m[1]}_spec.js" }
  watch(%r{^spec/javascripts/.+_spec(\.js|\.js\.coffee)$})
end

guard 'rspec',
  all_on_start: false,
  all_after_pass: false do

  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }

  # Rails example
  watch(%r{^app/(.+)\.rb$})                           { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^app/(.*)(\.erb|\.haml)$})                 { |m| "spec/#{m[1]}#{m[2]}_spec.rb" }
  watch(%r{^spec/support/(.+)\.rb$})                  { "spec" }

  # Capybara features specs
  watch(%r{^app/views/(.+)/.*\.(erb|haml)$})          { |m| "spec/features/#{m[1]}_spec.rb" }
end
}

# ====================
# BOWER
# ====================

generate('bower_rails:initialize json')

file 'Bowerfile',
%q{
asset 'foundation'
asset 'underscore'
asset 'handlebars'
asset 'font-awesome'
}

rake 'bower:install'

# ====================
# FINALIZE
# ====================

run "rm public/index.html"
run "rm README"

run 'cp config/environments/production.rb config/environments/staging.rb'
run 'cp config/database.yml config/database.example.yml'

run 'rm -rf test'

run 'touch .env'
run 'touch .env.example'

# Set up gitignore and commit base state
file '.gitignore',
%q{
.bundle
log/*.log
/log/*.pid
tmp/*
/coverage/*
public/system/*
public/stylesheets/compiled/*
config/database.yml
db/*.sqlite3
db/structure.sql
*.swp
*.swo
.DS_Store
**/.DS_STORE
.env
}, :force => true

git :init
git :add => "."
git :commit => "-a -m 'Initial project commit'"

puts "*****************************************************************"
puts "We have liftoff! Don't forget to:"
puts "* set up your smtp configuration (config/initializers/smtp.rb)"
puts "* set a proper airbrake key (config/initializers/airbrake.rb)"
puts "* set up proper hostnames (config/initializers/hosts.rb)"
puts "*****************************************************************"
