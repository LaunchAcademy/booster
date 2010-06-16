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
  #run "curl -s -L #{from} > #{to}"
  file to, open(from).read
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

add_source 'http://gems.github.com/'

gem 'RedCloth', '~> 4.2', :require => 'redcloth'
gem 'bluecloth', '~> 2.0'
gem 'will_paginate', :require => "will_paginate"
gem 'paperclip', :require => "paperclip"
gem "alexdunae-validates_email_format_of", :require => "validates_email_format_of"
gem 'stringex', :require => "stringex"
#gem 'newrelic_rpm'
gem 'authlogic', :require => "authlogic"
#gem 'searchlogic', :require => "searchlogic"
gem 'inherited_resources', :require => 'inherited_resources'
gem 'formtastic', :require => 'formtastic'
gem 'capistrano'
gem 'erubis'
gem 'hoptoad_notifier'

#==================
# Development Gems
#==================
gem "inaction_mailer",
  :require => 'inaction_mailer/force_load',
  :group => 'development'
  
#==================
# Test Gems
#==================
gem 'rspec-rails', '2.0.0.beta.12', :require => false, :group => 'test'
gem 'jferris-mocha', :require => 'mocha', :group => "test"
gem 'factory_girl', :require => 'factory_girl', :group => "test"
gem 'shoulda', :require => 'shoulda', :group => "test"
gem "cucumber", :group => "test"
gem 'metric_fu', :require => 'metric_fu', :group => 'test'
gem "webrat", :require => "webrat", :group => 'test'

run 'bundle install'

prepend_to_file('config/environment.rb', "PROJECT_NAME = 'CHANGE'\r\n")

FileUtils.rm_rf("test")

generate(:rspec)
generate(:blue_ridge)
generate(:hoptoad, '--api-key abcdefg123456')

#====================
# PLUGINS
#====================

plugin 'limerick_rake', :git => "git://github.com/thoughtbot/limerick_rake.git"
plugin 'superdeploy', :git => "git://github.com/saizai/superdeploy.git"
plugin 'tab_menu', :git => "git://github.com/dpickett/tab_menu.git"
#plugin 'spreadhead', :git => "git://github.com/jeffrafter/spreadhead.git"
plugin 'silky_buttons', :git => "git://github.com/CodeOfficer/silky-buttons-for-rails.git"
plugin 'blue_ridge', :git => "git://github.com/relevance/blue-ridge.git"

#====================
# APP
#====================

file 'app/controllers/application_controller.rb', 
%q{class ApplicationController < ActionController::Base
  protect_from_forgery
  layout 'application'

  include HoptoadNotifier::Catcher
end
}, :force => true

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

run 'rm public/javascripts/prototype.js'
run 'rm public/javascripts/effects.js'
run 'rm public/javascripts/dragdrop.js'
run 'rm public/javascripts/controls.js'

file 'public/stylesheets/ie7.css', ""
file 'public/stylesheets/ie6.css', ""

file 'app/views/layouts/application.html.erb', 
%q{<!DOCTYPE html>
<html>
  <head>
    <title><%= yield(:title) %> || <%= PROJECT_NAME.humanize %></title>

    <meta name="description" content="<%= yield(:description) || PROJECT_NAME.humanize %>" />
    <meta name="keywords" content="<%= yield(:keywords) || PROJECT_NAME.humanize %>" />
    <%= csrf_meta_tag %>

    <%= stylesheet_link_tag "reset", "under_construction", "960", "silky_buttons" %>    
    <!--[if lte IE 7]><%= stylesheet_link_tag "ie7" %><![endif]-->
    <!--[if lte IE 6]><%= stylesheet_link_tag "ie6" %><![endif]-->

    <%= yield :extra_header %>
  </head>
  <body class="<%= body_class %>">
    <%= render :partial => 'layouts/flashes' -%>
    <%= yield %>

    <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.min.js"
      type="text/javascript"></script>
    <script src="http://ajax.googleapis.com/ajax/libs/jqueryui/1.7.2/jquery-ui.min.js"
      type="text/javascript"></script>

    <%= javascript_include_tag 'xhr_fix', 
      'jquery.under_construction.js',
      'application' %>

    <%= yield :extra_footer %>
  </body>
</html>
}, :force => true

#====================
# INITIALIZERS
#====================

initializer 'action_mailer_configs.rb', 
%q{ActionMailer::Base.smtp_settings = {
    :address => "",
    :port    => 25,
    :domain  => ""
}
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

initializer 'mocks.rb', 
%q{# Rails 2 doesn't like mocks

# This callback will run before every request to a mock in development mode, 
# or before the first server request in production. 

Rails.configuration.to_prepare do
  Dir[File.join(RAILS_ROOT, 'spec', 'mocks', RAILS_ENV, '*.rb')].each do |f|
    load f
  end
end
}

initializer 'requires.rb', 
%q{require 'redcloth'

Dir[File.join(RAILS_ROOT, 'lib', 'extensions', '*.rb')].each do |f|
  require f
end

Dir[File.join(RAILS_ROOT, 'lib', '*.rb')].each do |f|
  require f
end
}

initializer 'time_formats.rb', 
%q{# Example time formats
{ :short_date => "%x", :long_date => "%a, %b %d, %Y" }.each do |k, v|
  ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.update(k => v)
end
}

initializer 'validation_fix.rb',
%q{
  ActionView::Base.field_error_proc = Proc.new { |html_tag, instance|
  "<span class=\"fieldWithErrors\">#{html_tag}</span>" } 
}

# ====================
# CONFIG
# ====================

capify!

file 'config/database.yml', 
%q{<% PASSWORD_FILE = File.join(Rails.root, '..', '..', 'shared', 'config', 'dbpassword') %>

development:
  adapter: mysql
  database: <%= PROJECT_NAME %>_development
  username: root
  password: 
  host: localhost
  encoding: utf8
  
test:
  adapter: mysql
  database: <%= PROJECT_NAME %>_test
  username: root
  password: 
  host: localhost
  encoding: utf8
}, :force => true

FileUtils.cp('config/database.yml', 'config/database.example.yml')

file 'config/initializers/debugging.rb',
%q{if %w(development test).include?(RAILS_ENV)
  begin
    SCRIPT_LINES__
  rescue NameError
    SCRIPT_LINES__ = {}
  end
  begin
    require 'ruby-debug'
  rescue LoadError
    warn "Debugging will be unavailable: #{$!}"
  end
end
}

inside('db') do
  run "mkdir bootstrap"
end

# ====================
# TEST
# ====================

inside('spec') do
  FileUtils.touch("factories.rb")
end


file 'public/javascripts/xhr_fix.js',
%q{jQuery.ajaxSetup({ 
  'beforeSend': function(xhr) {xhr.setRequestHeader("Accept",
    "text/javascript")} 
});
}

# ====================
# Cucumber
# ====================
generate(:cucumber)

# ====================
# CSS
# ====================

#Eric Meyer's Reset
download("http://meyerweb.com/eric/tools/css/reset/reset.css", 
  "public/stylesheets/reset.css")
  
#960.gs
download("http://github.com/nathansmith/960-Grid-System/raw/master/code/css/960.css", 
  "public/stylesheets/960.css")

run "mkdir public/images/grid"
download("http://github.com/nathansmith/960-Grid-System/raw/master/code/img/12_col.gif",
  "public/images/grid/12_col.gif")

download("http://github.com/nathansmith/960-Grid-System/raw/master/code/img/16_col.gif",
  "public/images/grid/16_col.gif")

from_repo("dpickett", "under_construction",  
  "stylesheets/under_construction.css",
  "public/stylesheets/under_construction.css")

from_repo("dpickett", "under_construction", 
  "javascripts/jquery.under_construction.js",   
  "public/javascripts/jquery.under_construction.js")
  
generate(:formtastic_stylesheets)

generate(:silky_buttons)

# ====================
# FINALIZE
# ====================

run "rm public/index.html"
run "rm public/README"
run "rm public/favicon.ico"

# Set up gitignore and commit base state
file '.gitignore', <<-END
log/*.log
tmp/*
.DS\_Store
.DS_Store
db/test.sqlite3
db/development.sqlite3
/log/*.pid
/coverage/*
public/system/*
config/database.yml
*.swp
END

run 'find . \( -type d -empty \) -and \( -not -regex ./\.git.* \) -exec touch {}/.gitignore \;'
git :init
git :add => "."
git :commit => "-a -m 'Initial project commit'"
