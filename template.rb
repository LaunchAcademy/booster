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
  gem 'mocha',
    require: false
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
//= require vendor/underscore
//= require vendor/backbone
//= require vendor/handlebars
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

// Thoughtbot's Bourbon Mixins
@import "bourbon";

// Settings
@import "settings";

// Base Styles
@import "base/all";

// Layout Styles
@import "layout/all";

// Modules
@import "modules/all";

// Non-modular
@import "non_modular/all";

// Helpers
@import "helpers";

// Print Styles
@import "print";
}, force: true

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

initializer 'asset_pipeline_logging.rb',
%q{#credit: https://gist.github.com/2409513
if Rails.env.development?
  Rails.application.assets.logger = Logger.new('/dev/null')

  Rails::Rack::Logger.class_eval do
    def call_with_quiet_assets(env)
      previous_level = Rails.logger.level
      Rails.logger.level = Logger::ERROR if env['PATH_INFO'] =~ %r{^/assets/}
      call_without_quiet_assets(env)
    ensure
      Rails.logger.level = previous_level
    end
    alias_method_chain :call, :quiet_assets
  end

end
}
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

require 'rspec/rails'
require 'factory_girl'
require 'database_cleaner'
require 'shoulda'
require 'capybara/rspec'
require 'mocha/api'
require 'valid_attribute'

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

  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
end
}, :force => true

# ====================
# CSS
# ====================

[
  "base",
  "layout",
  "modules",
  "non_modular"
].each do |css_dir|
  run("mkdir app/assets/stylesheets/#{css_dir}")
end

# ====================
# Base Stylessheets
# ====================

# Import base stylesheets
file 'app/assets/stylesheets/base/_all.css.scss',
%q{@import "reset";
@import "typography";
@import "forms";
}

# Reset
file 'app/assets/stylesheets/base/_reset.css.scss',
%q{
// Most of this is taken from HTML5 Boilerplate and Normalize
//
// http://html5boilerplate.com/
// http://necolas.github.com/normalize.css/

// Border box, all the things
* {
  @include box-sizing(border-box);
  *behavior: url(/assets/vendor/htc/boxsizing.htc);
}

// HTML5 display definitions

article, aside, details, figcaption, figure, footer, header, hgroup, nav, section { display: block; }
audio, canvas, video { display: inline-block; *display: inline; *zoom: 1; }
audio:not([controls]) { display: none; }
[hidden] { display: none; }

// Base

// 1. Correct text resizing oddly in IE6/7 when body font-size is set using em units
// 2. Prevent iOS text size adjust on device orientation change, without disabling user zoom: h5bp.com/g

html { font-size: 100%; -webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; }

html, button, input, select, textarea { font-family: sans-serif; color: #222; }

body {
  margin: 0;
  color: $bodyFontColor;
  font-family: $bodyFontFamily;
  font-size: $baseFontSize;
  line-height: 1.4;
}

// * Remove text-shadow in selection highlight: h5bp.com/i
// * These selection declarations have to be separate
::-moz-selection { background: $selectionBackgroundColor; color: $selectionTextColor; text-shadow: none; }
::selection { background: $selectionBackgroundColor; color: $selectionTextColor; text-shadow: none; }

// Links
a {
  color: $linkColor;
  text-decoration: none;
}
a:hover { color: $linkHoverColor; }
a:focus { outline: thin dotted; }

// Improve readability when focused and hovered in all browsers: h5bp.com/h
a:hover, a:active { outline: 0; }

// Embedded content
//
// * 1. Improve image quality when scaled in IE7: h5bp.com/d
// * 2. Remove the gap between images and borders on image containers: h5bp.com/i/440
img { border: 0; -ms-interpolation-mode: bicubic; vertical-align: middle; }

// * Correct overflow not hidden in IE9
svg:not(:root) { overflow: hidden; }

figure { margin: 0; }

// Tables
table { border-collapse: collapse; border-spacing: 0; }
td { vertical-align: top; }

// Chrome Frame Prompt
.chromeframe { margin: 0.2em 0; background: #ccc; color: black; padding: 0.2em 0; }
}

# Typography
file 'app/assets/stylesheets/base/_typography.css.scss',
%q{h1, h2, h3, h4, h5, h6 {
  margin-top: 0;
  margin-bottom: $baseFontSize;
  color: $headerFontColor;
  font-family: $headerFontFamily;
  font-weight: $headerFontWeight;
  text-rendering: optimizeLegibility;
  small { font-size: 60%; color: lighten($headerFontColor, 30%); line-height: 0; }
}

p {
  margin-top: 0;
}

b, strong { font-weight: bold; }

blockquote { margin: 1em 40px; }

hr { display: block; height: 1px; border: 0; border-top: 1px solid #ccc; margin: 1em 0; padding: 0; }

// Redeclare monospace font family: h5bp.com/j
pre, code, kbd, samp { font-family: monospace, serif; _font-family: 'courier new', monospace; font-size: 1em; }

// Improve readability of pre-formatted text in all browsers
pre { white-space: pre; white-space: pre-wrap; word-wrap: break-word; }

q { quotes: none; }
q:before, q:after { content: ""; content: none; }

small { font-size: 85%; }

// Lists
dd { margin: 0 0 0 40px; }
ul, ol { list-style: none; list-style-image: none; margin: 0; padding: 0; }
li { margin-bottom: 1em; }

// Position subscript and superscript content without affecting line-height: h5bp.com/k
sub, sup { font-size: 75%; line-height: 0; position: relative; vertical-align: baseline; }
sup { top: -0.5em; }
sub { bottom: -0.25em; }
}

# Forms
file 'app/assets/stylesheets/base/_forms.css.scss',
%q{form { margin: 0; }
fieldset { border: 0; margin: 0; padding: 0; }

// Indicate that 'label' will shift focus to the associated form element
label { cursor: pointer; }

// * 1. Correct color not inheriting in IE6/7/8/9
// * 2. Correct alignment displayed oddly in IE6/7
legend {
  border: 0;
  margin-bottom: $formSpacing;
  *margin-left: -7px;
  padding: 0;
  white-space: normal;
}

// * 1. Correct font-size not inheriting in all browsers
// * 2. Remove margins in FF3/4 S5 Chrome
// * 3. Define consistent vertical alignment display in all browsers
button, input, select, textarea { font-size: 100%; margin: 0; vertical-align: baseline; *vertical-align: middle; }

// * 1. Define line-height as normal to match FF3/4 (set using !important in the UA stylesheet)
button, input { line-height: normal; }

// * 1. Display hand cursor for clickable form elements
// * 2. Allow styling of clickable form elements in iOS
// * 3. Correct inner spacing displayed oddly in IE7 (doesn't effect IE6)
button, input[type="button"], input[type="reset"], input[type="submit"] {
  margin-bottom: $formSpacing;
  cursor: pointer;
  -webkit-appearance: button;
  *overflow: visible;
}

// * Re-set default cursor for disabled elements
button[disabled], input[disabled] { cursor: default; }

// * Remove inner padding and border in FF3/4: h5bp.com/l
button::-moz-focus-inner, input::-moz-focus-inner { border: 0; padding: 0; }

 // * 1. Remove default vertical scrollbar in IE6/7/8/9
 // * 2. Allow only vertical resizing
textarea { overflow: auto; vertical-align: top; resize: vertical; }

input[type="text"],
input[type="password"],
input[type="date"],
input[type="datetime"],
input[type="email"],
input[type="number"],
input[type="search"],
input[type="tel"],
input[type="time"],
input[type="url"],
textarea {
  display: block;
  width: 100%;
  border: 1px solid darken($white, 20%);
  border-radius: 3px;
  @include box-shadow(inset 0 1px 2px rgba(0,0,0,0.1));
  color: rgba(0,0,0,0.75);
  margin: 0 0 $formSpacing 0;
  padding: ($formSpacing - 3) $formSpacing;
  // height: ($formSpacing * 4);
  @include transition(all 0.15s linear);

  &.oversize { font-size: ms(1); padding: (($formSpacing - 4) / 2) ($formSpacing / 2); }

  &:focus { background: darken($white, 2%); outline: none !important; border-color: darken($white, 30%); }
  &[disabled] { background-color: #ddd; }
}

// Colors for form validity
input:valid, textarea:valid {  }
input:invalid, textarea:invalid { background-color: #f0dddd; }

// Errors
.error {
  display: inline-block;
  margin-bottom: $formSpacing;
  color: $errorFontColor;
  background: $errorColor;
}
}

# ====================
# Layout Stylessheets
# ====================

# Import layout stylesheets
file 'app/assets/stylesheets/layout/_all.css.scss',
%q{@import "containers";
}

# Layout Containers
file 'app/assets/stylesheets/layout/_containers.css.scss',
%q{// Layout Containers
}

# ====================
# Module Stylessheets
# ====================

# Import modules stylesheets
file 'app/assets/stylesheets/modules/_all.css.scss',
%q{@import "media";
@import "flashes";
@import "navigation";
@import "buttons";
}

# Flash Styles
file 'app/assets/stylesheets/modules/_flashes.css.scss',
%q{.flash {
  padding: 20px;
  text-align: center;
}

.flash-error {
  background: $errorColor;
}

.flash-notice {
  background: $noticeColor;
}
}

# Button Styles
file 'app/assets/stylesheets/modules/_buttons.css.scss',
%q{.btn {
  display: inline-block;
  padding: $btnBase ($btnBase * 2) ($btnBase + 1);
  margin: 0;
  width: auto;
  border: none;
  outline: none;
  background-color: $btnBaseColor;
  border-radius: $btnRadius;
  @include transition(background-color, .10s, ease-in-out);
  color: $white;
  cursor: pointer;
  text-decoration: none;
  text-align: center;
  line-height: normal;
  font-size: $btnBaseFontSize; // 15px
  font-weight: bold;

  &:hover {
    color: $white;
    background-color: lighten($btnBaseColor, 20%);
  }
}

input[type=submit].button, button.button { -webkit-appearance: none; }
}

# Media Object Styles
file 'app/assets/stylesheets/modules/_media.css.scss',
%q{.media,
.media .media-body {
  overflow: hidden;
  *overflow: visible;
  zoom: 1;
}

.media {
  margin-bottom: 1em;
}

.media-object {
  float: left;
  margin-right: 1em;

  &.flipped {
    float: right;
    margin-right: 0;
    margin-left: 1em;
  }
}

.media-body {
  > :last-child { margin-bottom: 0; }
}
}

# Navigation module Styles
file 'app/assets/stylesheets/modules/_navigation.css.scss',
%q{.nav {
  height: $navBarHeight;
  padding: 0;
  margin: 0;

  > li {
    float: left;
    display: block;
    border-right: 1px solid $grayBorder;
    float: left;
    display: block;
    position: relative;
    padding: 0;
    margin: 0;
    line-height: $navBarHeight - 2;

    &:last-child, &.last {
      border-right: none;
    }

    > a {
      padding: 0 ($navBarHeight / 2);

      &:hover { color: $linkHoverColor; }
    }
  }
}
}

# ====================
# Non-Modular Stylessheets
# ====================

# Import modules stylesheets
file 'app/assets/stylesheets/non_modular/_all.css.scss',
%q{// Import non-modular stylesheets
}

# Helpers Stylesheet
file 'app/assets/stylesheets/_helpers.css.scss',
%q{// For image replacement
.is-text-hidden { display: block; border: 0; text-indent: -999em; overflow: hidden; background-color: transparent; background-repeat: no-repeat; text-align: left; direction: ltr; *line-height: 0; }
.is-text-hidden br { display: none; }

// Hide from both screenreaders and browsers: h5bp.com/u
.is-hidden { display: none !important; visibility: hidden; }

// Hide only visually, but have it available for screenreaders: h5bp.com/v
.is-visually-hidden { border: 0; clip: rect(0 0 0 0); height: 1px; margin: -1px; overflow: hidden; padding: 0; position: absolute; width: 1px; }

// Extends the .visuallyhidden class to allow the element to be focusable when navigated to via the keyboard: h5bp.com/p
.is-visually-hidden.focusable:active, .is-visually-hidden.focusable:focus { clip: auto; height: auto; margin: 0; overflow: visible; position: static; width: auto; }

// Hide visually and from screenreaders, but maintain layout
.is-invisible { visibility: hidden; }

.right { float: right; }
.left { float: left; }
}

# Print Stylesheet
file 'app/assets/stylesheets/_print.css.scss',
%q{@media print {
  * { background: transparent !important; color: black !important; box-shadow:none !important; text-shadow: none !important; filter:none !important; -ms-filter: none !important; } /* Black prints faster: h5bp.com/s */
  a, a:visited { text-decoration: underline; }
  a[href]:after { content: " (" attr(href) ")"; }
  abbr[title]:after { content: " (" attr(title) ")"; }
  .is-text-hidden a:after, a[href^="javascript:"]:after, a[href^="#"]:after { content: ""; }  /* Don't show links for images, or javascript/internal links */
  pre, blockquote { border: 1px solid #999; page-break-inside: avoid; }
  thead { display: table-header-group; } /* h5bp.com/t */
  tr, img { page-break-inside: avoid; }
  img { max-width: 100% !important; }
  @page { margin: 0.5cm; }
  p, h2, h3 { orphans: 3; widows: 3; }
  h2, h3 { page-break-after: avoid; }
}
}

# Settings Stylesheet
file 'app/assets/stylesheets/_settings.css.scss',
%q{// ============================================================================
// Grid Settings
// These settings override the defaults for Neat grid system
// ============================================================================

$max-width: 960px;

// ============================================================================
// Colors
// ============================================================================

$white: #ffffff;
$black: #000000;

$linkColor: #3d9ec6;
$linkHoverColor: #06e;
$bodyFontColor: #8d8d8d;
$bodyFontColorDark: #777777;

// ============================================================================
// Buttons
// ============================================================================

$btnRadius: 2px;
$btnBase: 10px;

$btnBaseColor: #ed953f;
$btnBaseFontSize: 1.153846154em;

// ============================================================================
// Fonts
// ============================================================================

// Font stacks
// There are more included by default from Bourbon
$arial: Arial, "Helvetica Neue", Helvetica, sans-serif;

$bodyFontFamily: $helvetica;
$headerFontFamily: $helvetica;
$headerFontColor: #658193;
$headerFontWeight: normal;

// ============================================================================
// Font Sizes
// ============================================================================

$baseFontSize: 16px;

// ============================================================================
// Navigation
// ============================================================================

$navBarHeight: 27px;
$navTabsHeight: 45px;

// ============================================================================
// Borders
// ============================================================================

$grayBorder: #e1e1e1;

// ============================================================================
// Forms
// ============================================================================

$formSpacing: $baseFontSize;

// ============================================================================
// Flashes
// ============================================================================

$errorFontColor: $white;
$errorColor: #fe8c8c;

$noticeFontColor: $white;
$noticeColor: #07a300;

// ============================================================================
// Misc
// ============================================================================

$selectionBackgroundColor: pink;
$selectionTextColor: $white;
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
# JavaScript
# ===========

run("mkdir -p vendor/assets/javascripts/vendor")
download("http://documentcloud.github.com/underscore/underscore.js", "vendor/assets/javascripts/vendor/underscore.js")
download("https://raw.github.com/douglascrockford/JSON-js/master/json2.js", "vendor/assets/javascripts/vendor/json2.js")
download("http://builds.handlebarsjs.com.s3.amazonaws.com/handlebars-v2.0.0.js", "vendor/assets/javascripts/vendor/handlebars.js")

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
