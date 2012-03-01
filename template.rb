# Enlightened template.rb
# from Dan Pickett
# based on Suspenders by Thoughtbot
# influenced by Mike Gunderloy's rails template - http://gist.github.com/145676

require 'open-uri'
require 'yaml'
require 'base64'

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

#====================
# GEMS
#====================

file 'Gemfile', <<-END, :force => true
source :rubygems

gem 'rails', '3.2.1'

gem 'sqlite3'
gem 'pg'

group :assets do
  gem 'sass-rails'
  gem 'coffee-rails'
  gem 'uglifier'
  gem 'bourbon'
end

gem 'jquery-rails'

gem 'bluecloth', '~> 2.0'
gem 'kaminari'
# gem 'slugged'
gem 'inherited_resources'
gem 'simple_form'
gem 'erubis'
gem 'airbrake'
gem 'haml'
gem 'devise'
gem 'configatron'
gem 'bourbon'
gem 'tab_menu'
gem "twitter-bootstrap-rails", "~> 2.0.1.0"

group :development do
  gem 'rspec-rails'
  
  gem 'guard'
  gem 'guard-livereload'
  gem 'guard-rspec'
  gem 'guard-bundler'
  gem 'guard-spin'
  
  gem 'rb-fsevent'
  gem 'growl'
  
  gem 'heroku'
end

group :test do
  gem 'rspec-rails'
  gem 'mocha'
  gem 'bourne'
  gem 'factory_girl'
  gem 'shoulda'
  gem "capybara"
  gem 'database_cleaner'
  gem 'launchy'
  gem 'postmaster_general', '~> 0.1'
  # Pretty printed test output
  gem 'fuubar'
end

gem 'pry', :group => [:development, :test]

END

run 'bundle install'

file '.rvmrc', "rvm 1.9.3@#{app_name}"

FileUtils.rm_rf("test")

generate("rspec:install")
file '.rspec',
%q{
  --colour
  --format Fuubar
}, force: true


generate(:airbrake, '--api-key abcdefg123456')
generate('devise:install')
generate('bootstrap:install')

run "rm app/assets/javascripts/bootstrap.js.coffee"
run "rm app/assets/stylesheets/bootstrap.css.less"

file 'features/support/factory_girl.rb',
%q{require "factory_girl"

require Rails.root.join("spec/support/factories")
require "factory_girl/step_definitions"
}

#====================
# APP
#====================

file 'config/database_pg.example.yml', 
%q{ # PostgreSQL. Versions 7.4 and 8.x are supported.
#
# Install the ruby-postgres driver:
#   gem install ruby-postgres
# On Mac OS X:
#   gem install ruby-postgres -- --include=/usr/local/pgsql
# On Windows:
#   gem install ruby-postgres
#       Choose the win32 build.
#       Install PostgreSQL and put its /bin directory on your path.

development:
  adapter: postgresql
  encoding: unicode
  database: _development
  pool: 5
  username: 
  password: 


test:
  adapter: postgresql
  encoding: unicode
  database: _test
  pool: 5
  username: 
  password: 

}

file 'app/helpers/application_helper.rb', 
%q{module ApplicationHelper
  def body_class
    "#{controller.controller_name} #{controller.controller_name}-#{controller.action_name}"
  end
end
}, :force => true

file 'app/views/layouts/_flashes.html.erb', 
%q{<div id="flash">
  <% flash.each do |key, value| -%>
    <div id="flash_<%= key %>"><%=h value %></div>
  <% end -%>
</div>
}

file 'app/assets/javascripts/application.js', 
%q{
// This is a manifest file that'll be compiled into application.js, which will include all the files
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
//= require twitter/bootstrap
//= require xhr_fix
//= require underscore
//= require backbone
//= require handlebars
//= require_tree .

}, force: true

file 'app/assets/stylesheets/application.css', 
%q{
  /*
   * This is a manifest file that'll be compiled into application.css, which will include all the files
   * listed below.
   *
   * Any CSS and SCSS file within this directory, lib/assets/stylesheets, vendor/assets/stylesheets,
   * or vendor/assets/stylesheets of plugins, if any, can be referenced here using a relative path.
   *
   * You're free to add application-wide styles to this file and they'll appear at the top of the
   * compiled file, but it's generally better to create a new file per style scope.
   *
   *= require_self
   *= require twitter/bootstrap
   *= require under_construction
   *= require main
  */


}, force: true

file 'app/assets/stylesheets/ie7.css.scss', ""
file 'app/assets/stylesheets/main.css.scss', ""

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
    <!--[if lte IE 7]><%= stylesheet_link_tag "ie7" %><![endif]-->

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

initializer 'hosts.rb',
%q{configatron.default_host = {
  :development => "localhost:3000",
  :test => "localhost:3000",
  :production => "appname.com",
  :staging => "staging.appname.com"
}[Rails.env.to_sym]

ActionMailer::Base.default_url_options[:host] = configatron.default_host
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
end
}

initializer 'validation_fix.rb',
%q{ActionView::Base.field_error_proc = Proc.new { |html_tag, instance|
  "<span class=\"fieldWithErrors\">#{html_tag}</span>".html_safe }
}

initializer 'pry.rb',
%q{silence_warnings do
  begin
    require 'pry'
    IRB = Pry
  rescue LoadError
  end
end
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
  FileUtils.touch("support/factories.rb")
end


file 'app/assets/javascripts/xhr_fix.js',
%q{jQuery.ajaxSetup({ 
  'beforeSend': function(xhr) {xhr.setRequestHeader("Accept",
    "text/javascript")} 
});
}

file 'spec/spec_helper.rb', 
%q{
  require 'rubygems'
  require 'postmaster_general'

  ENV["RAILS_ENV"] ||= 'test'
  require File.expand_path("../../config/environment", __FILE__)

  require 'pry'

  require 'rspec/rails'
  require 'factory_girl'
  require 'database_cleaner'
  require 'shoulda'
  require 'capybara/rspec'
  PostmasterGeneral.log_directory = Rails.root.join("tmp/rendered_emails")

  # Requires supporting ruby files with custom matchers and macros, etc,
  # in spec/support/ and its subdirectories.

  Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

  RSpec.configure do |config|
    # == Mock Framework
    #
    # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
    #
    # config.mock_with :mocha
    # config.mock_with :flexmock
    # config.mock_with :rr
    config.mock_with :mocha

    # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
    config.fixture_path = "spec/fixtures"

    # If you're not using ActiveRecord, or you'd prefer not to run each of your
    # examples within a transaction, remove the following line or assign false
    # instead of true.
    config.use_transactional_fixtures = true

    config.treat_symbols_as_metadata_keys_with_true_values = true
    config.filter_run focus: true
    config.run_all_when_everything_filtered = true
  end
}, :force => true

# ====================
# CSS
# ====================

from_repo("dpickett", "under_construction",  
  "stylesheets/under_construction.css",
  "app/assets/stylesheets/under_construction.css")

from_repo("dpickett", "under_construction", 
  "javascripts/jquery.under_construction.js",   
  "app/assets/javascripts/jquery.under_construction.js")
  
file 'app/assets/javascripts/xhr_fix.js',
%q{jQuery.ajaxSetup({ 
  'beforeSend': function(xhr) {xhr.setRequestHeader("Accept",
    "text/javascript")} 
});
}
  
# ==============
# JS
# ==============

generate('simple_form:install --bootstrap')

# ===========
# BACKBONE
# ===========

download("http://documentcloud.github.com/backbone/backbone.js", "app/assets/javascripts/backbone.js")
download("http://documentcloud.github.com/underscore/underscore.js", "app/assets/javascripts/underscore.js")
download("https://raw.github.com/douglascrockford/JSON-js/master/json2.js", "app/assets/javascripts/json2.js")
download("https://github.com/downloads/wycats/handlebars.js/handlebars.1.0.0.beta.3.js", "app/assets/javascripts/handlebars.js")

# ===========
# GUARD
# ===========
[
  "",
  "spin",
  "livereload",
  "bundler",
  ""
].each do |guard_item|
  run "bundle exec guard init #{guard_item}"
end

# ====================
# FINALIZE
# ====================

run "rm public/index.html"
run "rm README"

run 'rake db:migrate'

# Set up gitignore and commit base state
file '.gitignore', %q{
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
}, :force => true

git :init
git :add => "."
git :commit => "-a -m 'Initial project commit'"
