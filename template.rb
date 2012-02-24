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

def rvm(cmd)
  run "bash -l -c \"rvm #{cmd}\""
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
  
  gem 'pry', :group => [:development, :test]
end
END

rvm "use 1.9.3@#{app_name} --create"
rvm "1.9.3@#{app_name} do gem install bundler"
rvm "1.9.3@#{app_name} do bundle install"

file '.rvmrc', "rvm 1.9.3@#{ARGV[0]}"

FileUtils.rm_rf("test")

generate("rspec:install")
file '.rspec',
%q{
  --colour
  --format Fuubar
}, force: true


generate(:airbrake, '--api-key abcdefg123456')
generate('devise:install')

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

file 'app/assets/stylesheets/ie7.css.scss', ""

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

    <%= stylesheet_link_tag "under_construction",
                            "application" %>
    <!--[if lte IE 7]><%= stylesheet_link_tag "ie7" %><![endif]-->

    <%= yield :extra_header %>
  </head>
  <body class="<%= body_class %>">
    <%= render :partial => 'layouts/flashes' -%>
    <%= yield %>

    <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.6.2/jquery.min.js"
      type="text/javascript"></script>
    <script src="http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.14/jquery-ui.min.js"
      type="text/javascript"></script>

    <%= javascript_include_tag 'xhr_fix', 
      'jquery.under_construction',
      'application',
      'underscore',
      'backbone',
      'handlebars' %>

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

# ====================
# CONFIG
# ====================

capify!

FileUtils.cp('config/database.yml', 'config/database_pg.example.yml')


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

file 'app/assets/stylesheets/simple_form.css.sass', 
%q{
/* ----- SimpleForm Styles ----- */

.simple_form
  div.input
    margin-bottom: 10px

  label
    float: left
    width: 100px
    text-align: right
    margin: 2px 10px

  .error
    clear:   left
    color:   black
    display: block
    margin-left: 120px
    font-size:    12px

  .hint
    clear: left
    margin-left: 120px
    font-size:    12px
    color: #555
    display: block
    font-style: italic

div.boolean, .simple_form input[type='submit']
  margin-left: 120px

div.boolean label, label.collection_radio
  float: none
  margin: 0

label.collection_radio
  margin-right: 10px
  vertical-align: -2px
  margin-left:   2px

.field_with_errors
  background-color: #ff3333

input.radio
  margin-right: 5px
  vertical-align: -3px

input.check_boxes
  margin-left: 3px
  vertical-align: -3px

label.collection_check_boxes
  float: none
  margin: 0
  vertical-align: -2px
  margin-left:   2px
}, :force => true
  
# ==============
# JS
# ==============

generate('simple_form:install')

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
  "livereload",
  "rspec",
  "bundler",
  "spin",
  ""
].each do |guard_item|
  run "bundle exec guard init #{guard_item}"
end

# ====================
# FINALIZE
# ====================

run "rm public/index.html"
run "rm README"

rake 'db:migrate'

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
*.swp
*.swo
.DS_Store
**/.DS_STORE
}, :force => true

git :init
git :add => "."
git :commit => "-a -m 'Initial project commit'"
