# Building RubyProf

## Requirements

1. Standalone version of Ruby, matching version of SketchUp.
2. Ruby DevKit
3. Bundler

## Building

1. Checkout: https://github.com/thomthom/ruby-prof (dev-su-hack)
2. Open a console with Ruby DevKit activated:

        SET PATH=c:\Ruby27-x64\bin;%PATH%
        c:\RubyDevKit64\devkitvars.bat

3. Use Bundler to build the extension:

        bundle exec rake compile

## Debugging

To trace what RubyProf do, use the `RUBY_PROF_TRACE` environment variable:

    ENV['RUBY_PROF_TRACE'] = "#{ENV['HOME']}\Desktop\trace16.log"
    ENV['RUBY_PROF_TRACE'] = "#{ENV['HOME']}\Desktop\trace17.log"
