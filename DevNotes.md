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

## Mac Builds

### Fixing Mac dylib references

Building gems on Mac leaves the binaries with full path references to the system
Ruby installation. They need to be updated before SketchUp can use them.

    install_name_tool -change /Users/tthomas2/.rvm/rubies/ruby-2.5.5/lib/libruby.2.5.dylib @executable_path/../Frameworks/Ruby.framework/Versions/Current/Ruby ruby_prof.bundle

There is also a copy of the .bundle in the ext/ruby_prof directory along with
the source code for the binary. This is probably the direct build output and
might be ignored. Until then, patch this as well.

    /Users/tthomas2/SourceTree/speedup/src/speedup/precompiled-gems/Ruby25/mac/Gems/gems/ruby-prof-0.17.0/ext/ruby_prof

### Directory Names

System Ruby builds the gem binary into something like
`extension/x86_64-darwin-15`. But in SketchUp it should be
`extension/x68_64-darwin`. The former appear to work, but will produce a
warning:

    Ignoring ruby-prof-0.17.0 because its extensions are not built. Try: gem pristine ruby-prof --version 0.17.0
