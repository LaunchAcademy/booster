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

file 'Gemfile', <<-END, :force => true
source 'http://rubygems.org/'
source 'http://gems.github.com/'

gem 'rails', '3.0.0.beta4'
gem 'sqlite3-ruby', :require => 'sqlite3'

gem 'RedCloth', '~> 4.2', :require => 'redcloth'
gem 'bluecloth', '~> 2.0'
gem 'will_paginate', :require => "will_paginate"
gem 'paperclip', :require => "paperclip"
gem "alexdunae-validates_email_format_of", :require => "validates_email_format_of"
gem 'stringex', :require => "stringex"
gem 'inherited_resources', :require => 'inherited_resources'
gem 'formtastic', :git => 'http://github.com/justinfrench/formtastic.git', :branch => 'rails3'
gem 'capistrano'
gem 'erubis'
gem 'hoptoad_notifier'
gem 'haml'
gem 'compass'
gem 'compass-960-plugin'
gem 'devise', :git => 'git://github.com/plataformatec/devise.git'

group :development do
  gem "inaction_mailer", :require => 'inaction_mailer/force_load'
  gem 'ruby-debug'
end

group :test do
  gem 'rspec-rails', '2.0.0.beta.12', :require => false
  gem 'jferris-mocha', :require => 'mocha'
  gem 'factory_girl', :require => 'factory_girl'
  gem 'shoulda', :require => 'shoulda'
  gem "cucumber"
  gem 'metric_fu', :require => 'metric_fu'
  gem "webrat", :require => "webrat"
end
END

run 'bundle install'

FileUtils.rm_rf("test")

generate(:rspec)
generate(:hoptoad, '--api-key abcdefg123456')
generate('devise:install')

#====================
# PLUGINS
#====================

plugin 'limerick_rake', :git => "git://github.com/thoughtbot/limerick_rake.git"
plugin 'superdeploy', :git => "git://github.com/saizai/superdeploy.git"
plugin 'tab_menu', :git => "git://github.com/dpickett/tab_menu.git"
#plugin 'spreadhead', :git => "git://github.com/jeffrafter/spreadhead.git"
plugin 'blue_ridge', :git => "git://github.com/relevance/blue-ridge.git", :branch => 'rails3'

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
%q{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" 
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
  <head>
    <meta http-equiv="Content-type" content="text/html; charset=utf-8" />

    <title><%= yield(:title) %> || PROJECT NAME</title>

    <meta name="description" content="<%= yield(:description) || "PROJECT DESCRIPTION" %>" />
    <meta name="keywords" content="<%= yield(:keywords) || "PROJECT KEYWORDS" %>" />
    <%= csrf_meta_tag %>

    <%= stylesheet_link_tag "reset", "under_construction", "960", "silky_buttons",
                            "formtastic", "formtastic_changes", "application" %>
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
  Time::DATE_FORMATS.update(k => v)
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
  run "mkdir support"
  FileUtils.touch("support/factories.rb")
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
  
generate('formtastic:install')

run 'compass init rails . --css-dir=public/stylesheets/compiled --sass-dir=app/stylesheets --using 960.gs'

# ====================
# FINALIZE
# ====================

run "rm public/index.html"
run "rm README"

file '.rvmrc', "rvm ree@#{ARGV[0]}"

# Set up gitignore and commit base state
file '.gitignore', %q{
.bundle
log/*.log
/log/*.pid
tmp/*
/coverage/*
public/system/*
config/database.yml
}, :force => true

git :init
git :add => "."
git :commit => "-a -m 'Initial project commit'"
