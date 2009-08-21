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
# PLUGINS
#====================

plugin 'limerick_rake', :git => "git://github.com/thoughtbot/limerick_rake.git"
plugin 'superdeploy', :git => "git://github.com/saizai/superdeploy.git"
plugin 'tab_menu', :git => "git://github.com/dpickett/tab_menu.git"

#====================
# GEMS
#====================

gem 'RedCloth', :lib => 'redcloth', :version => '~> 3.0.4'
gem 'thoughtbot-hoptoad_notifier', :lib => "hoptoad_notifier"
gem 'mislav-will_paginate', :lib => "will_paginate"
gem 'thoughtbot-paperclip', :lib => "paperclip"
gem "alexdunae-validates_email_format_of", :lib => "validates_email_format_of"
gem 'rsl-stringex', :lib => "stringex"
gem 'newrelic_rpm'
gem 'binarylogic-authlogic', :lib => "authlogic"
gem 'binarylogic-searchlogic', :lib => "searchlogic"
gem 'josevalim-inherited_resources', :lib => 'inherited_resources'
gem 'justinfrench-formtastic', :lib => 'formtastic'

#==================
# Development Gems
#==================
gem "cwninja-inaction_mailer",
  :lib => 'inaction_mailer/force_load',
  :source => 'http://gems.github.com',
  :env => 'development'
  
#==================
# Test Gems
#==================
gem 'jferris-mocha', :lib => 'mocha', :env => "test"
gem 'thoughtbot-factory_girl', :lib => 'factory_girl', :env => "test"
gem 'thoughtbot-shoulda', :lib => 'shoulda', :env => "test"
gem "cucumber", :env => "test"
gem 'jscruggs-metric_fu', 
  :lib => 'metric_fu', 
  :source => 'http://gems.github.com',
  :env => 'test'
gem "webrat", 
  :lib => "webrat",
  :env => 'test'
gem "jeremymcanally-pending", 
  :lib => "pending",
  :env => 'test'

rake("gems:install", :sudo => true)
# rake("gems:unpack")

prepend_to_file('config/environment.rb', "PROJECT_NAME = 'CHANGE'\r\n")

#====================
# APP
#====================

file 'app/controllers/application_controller.rb', 
%q{class ApplicationController < ActionController::Base

  helper :all

  protect_from_forgery

  include HoptoadNotifier::Catcher
end
}

file 'app/helpers/application_helper.rb', 
%q{module ApplicationHelper
  def body_class
    "#{controller.controller_name} #{controller.controller_name}-#{controller.action_name}"
  end
end
}

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
    <title><%= yield(:title) %> || <%= PROJECT_NAME.humanize %></title>
    <meta name="description" content="<%= yield(:meta_description) || PROJECT_NAME.humanize %>">
    <meta name="keywords" content="<%= yield(:meta_keywords) || PROJECT_NAME.humanize %>">
    
    <%= stylesheeet_link_tag "reset", "under_construction", "960" %>
    
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
}

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


initializer 'hoptoad.rb', 
%q{HoptoadNotifier.configure do |config|
  config.api_key = 'HOPTOAD-KEY'
end
}

initializer 'mocks.rb', 
%q{# Rails 2 doesn't like mocks

# This callback will run before every request to a mock in development mode, 
# or before the first server request in production. 

Rails.configuration.to_prepare do
  Dir[File.join(RAILS_ROOT, 'test', 'mocks', RAILS_ENV, '*.rb')].each do |f|
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

file 'Capfile', 
%q{load 'deploy' if respond_to?(:namespace) # cap2 differentiator
Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }
load 'config/deploy'
}

file 'config/database.yml', 
%q{<% PASSWORD_FILE = File.join(RAILS_ROOT, '..', '..', 'shared', 'config', 'dbpassword') %>

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
}

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

inside('test') do
  run "mkdir factories"
end

file 'test/shoulda_macros/forms.rb', 
%q{class ActiveSupport::TestCase
  def self.should_have_form(opts)
    model = self.name.gsub(/ControllerTest$/, '').singularize.downcase
    model = model[model.rindex('::')+2..model.size] if model.include?('::')
    http_method, hidden_http_method = form_http_method opts[:method]
    should "have a #{model} form" do
      assert_select "form[action=?][method=#{http_method}]", eval(opts[:action]) do
        if hidden_http_method
          assert_select "input[type=hidden][name=_method][value=#{hidden_http_method}]"
        end
        opts[:fields].each do |attribute, type|
          attribute = attribute.is_a?(Symbol) ? "#{model}[#{attribute.to_s}]" : attribute
          assert_select "input[type=#{type.to_s}][name=?]", attribute
        end
        assert_select "input[type=submit]"
      end
    end
  end

  def self.form_http_method(http_method)
    http_method = http_method.nil? ? 'post' : http_method.to_s
    if http_method == "post" || http_method == "get"
      return http_method, nil
    else
      return "post", http_method
    end
  end  
end
}

file 'test/shoulda_macros/pagination.rb', 
%q{class ActiveSupport::TestCase
  # Example:
  #  context "a GET to index logged in as admin" do
  #    setup do
  #      login_as_admin 
  #      get :index
  #    end
  #    should_paginate_collection :users
  #    should_display_pagination
  #  end
  def self.should_paginate_collection(collection_name)
    should "paginate #{collection_name}" do
      assert collection = assigns(collection_name), 
        "Controller isn't assigning to @#{collection_name.to_s}."
      assert_kind_of WillPaginate::Collection, collection, 
        "@#{collection_name.to_s} isn't a WillPaginate collection."
    end
  end
  
  def self.should_display_pagination
    should "display pagination" do
      assert_select "div.pagination", { :minimum => 1 }, 
        "View isn't displaying pagination. Add <%= will_paginate @collection %>."
    end
  end
  
  # Example:
  #  context "a GET to index not logged in as admin" do
  #    setup { get :index }
  #    should_not_paginate_collection :users
  #    should_not_display_pagination
  #  end
  def self.should_not_paginate_collection(collection_name)
    should "not paginate #{collection_name}" do
      assert collection = assigns(collection_name), 
        "Controller isn't assigning to @#{collection_name.to_s}."
      assert_not_equal WillPaginate::Collection, collection.class, 
        "@#{collection_name.to_s} is a WillPaginate collection."
    end
  end
  
  def self.should_not_display_pagination
    should "not display pagination" do
      assert_select "div.pagination", { :count => 0 }, 
        "View is displaying pagination. Check your logic."
    end
  end
end
}

file 'test/test_helper.rb', 
%q{ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'
require 'action_view/test_case'

class ActiveSupport::TestCase

  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false

  self.backtrace_silencers << :rails_vendor
  self.backtrace_filters   << :rails_root

end

class ActionView::TestCase
  # Enable UrlWriter when testing helpers
  include ActionController::UrlWriter
  # Default host for helper tests
  default_url_options[:host] = HOST
end
}

file 'public/javascripts/xhr_fix.js',
%q{jQuery.ajaxSetup({ 
  'beforeSend': function(xhr) {xhr.setRequestHeader("Accept",
    "text/javascript")} 
});
}

# ====================
# Cucumber
# ====================
run "script/generate cucumber"

# ====================
# CSS
# ====================

#Eric Meyer's Reset
download("http://meyerweb.com/eric/tools/css/reset/reset.css", 
  "public/stylesheets/reset.css")
  
#960.gs
from_repo("nathansmith", 
  "960-grid-system", 
  "code/css/960.css", 
  "public/stylesheets/960.css")

run "mkdir public/images/grid"
from_repo("nathansmith", 
  "960-grid-system", 
  "code/img/12_col.gif", 
  "public/images/grid/12_col.gif")
  
from_repo("nathansmith", 
  "960-grid-system", 
  "code/img/16_col.gif",
  "public/images/grid/16_col.gif")

from_repo("dpickett", "under_construction",  
  "stylesheets/under_construction.css",
  "public/stylesheets/under_construction.css")

from_repo("dpickett", "under_construction", 
  "script/jquery.under_construction.js",   
  "public/javascripts/jquery.under_construction.js")

# ====================
# FINALIZE
# ====================

run "rm public/index.html"
run "rm public/README"
run "rm public/favicon.ico"

# Set up gitignore and commit base state
file '.gitignore', <<-END
log/*.log
tmp/**/*
.DS\_Store
.DS_Store
db/test.sqlite3
db/development.sqlite3
/log/*.pid
/coverage/*
public/system/*
tmp/metric_fu/*
tmp/sent_mails/*
END

run 'find . \( -type d -empty \) -and \( -not -regex ./\.git.* \) -exec touch {}/.gitignore \;'
git :init
git :add => "."
git :commit => "-a -m 'Initial project commit'"
