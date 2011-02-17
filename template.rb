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
source 'http://rubygems.org/'

gem 'rails', '3.0.4'

gem 'bluecloth', '~> 2.0'
gem 'will_paginate', '3.0.pre2'
gem 'slugged'
gem 'inherited_resources'
gem 'simple_form'
gem 'erubis'
gem 'hoptoad_notifier'
gem 'haml'
gem 'compass'
gem 'compass-960-plugin'
gem 'devise'
gem 'configatron'

group :development do
  gem 'rspec-rails'
  gem 'pickler'
  gem 'ruby-debug'
end

group :test do
  gem 'rspec-rails'
  gem 'mocha'
  gem 'bourne'
  gem 'factory_girl'
  gem 'shoulda'
  gem "capybara"
  gem 'database_cleaner'
  gem 'cucumber-rails'
  gem 'cucumber'
  gem 'launchy'
  gem 'postmaster_general', '~> 0.1'
end
END

run 'bundle install'

FileUtils.rm_rf("test")

generate("rspec:install")

generate(:hoptoad, '--api-key abcdefg123456')
generate('devise:install')
generate('cucumber:install', '--capybara --rspec')

file 'features/support/factory_girl.rb',
%q{require "factory_girl"

require Rails.root.join("spec/support/factories")
require "factory_girl/step_definitions"
}

#====================
# PLUGINS
#====================

plugin 'tab_menu', :git => "git://github.com/dpickett/tab_menu.git"

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
run 'rm public/javascripts/rails.js'

file 'public/stylesheets/ie7.css', ""
file 'public/stylesheets/ie6.css', ""

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

    <%= stylesheet_link_tag "compiled/grid", "compiled/text", "under_construction",
                            "formtastic", "formtastic_changes", "compiled/application" %>
    <!--[if lte IE 7]><%= stylesheet_link_tag "ie7" %><![endif]-->
    <!--[if lte IE 6]><%= stylesheet_link_tag "ie6" %><![endif]-->

    <%= yield :extra_header %>
  </head>
  <body class="<%= body_class %>">
    <%= render :partial => 'layouts/flashes' -%>
    <%= yield %>

    <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js"
      type="text/javascript"></script>
    <script src="http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.5/jquery-ui.min.js"
      type="text/javascript"></script>

    <%= javascript_include_tag 'xhr_fix', 
      'jquery.under_construction.js',
      'application' %>

    <%= yield :extra_footer %>
    <%= whereuat unless Rails.env == 'production' %>
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

initializer 'whereuat.rb',
%q{require 'whereuat'

  Whereuat.configure do |config|
    config.pivotal_tracker_token   = "tracker_token"
    config.pivotal_tracker_project = "pt_proj"
  end
}

initializer 'debugging.rb',
%q{if %w(development test).include?(Rails.env)
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

# ====================
# CONFIG
# ====================

capify!

FileUtils.cp('config/database.yml', 'config/database.example.yml')


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
# CSS
# ====================

from_repo("dpickett", "under_construction",  
  "stylesheets/under_construction.css",
  "public/stylesheets/under_construction.css")

from_repo("dpickett", "under_construction", 
  "javascripts/jquery.under_construction.js",   
  "public/javascripts/jquery.under_construction.js")
  
# ==============
# JS
# ==============
from_repo("rails", "jquery-ujs", "src/rails.js", "public/javascripts/rails.js")  

generate('simple_form:install')

run 'bundle exec compass init rails . -r ninesixty --css-dir=public/stylesheets/compiled --sass-dir=app/stylesheets --using 960 --syntax scss'

# ====================
# FINALIZE
# ====================

run "rm public/index.html"
run "rm README"

file '.rvmrc', "rvm ree@#{ARGV[0]}"

rake 'db:migrate'

# Set up gitignore and commit base state
file '.gitignore', %q{
.bundle
log/*.log
/log/*.pid
tmp/*
/coverage/*
public/system/*
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
