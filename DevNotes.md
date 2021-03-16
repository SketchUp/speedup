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

otool -L ruby_prof.bundle 

Ruby 2.5

    install_name_tool -change /Users/tthomas2/.rvm/rubies/ruby-2.5.5/lib/libruby.2.5.dylib @executable_path/../Frameworks/Ruby.framework/Versions/Current/Ruby ruby_prof.bundle

Ruby 2.2

    install_name_tool -change /Users/tthomas2/.rvm/rubies/ruby-2.2.10/lib/libruby.2.2.0.dylib @executable_path/../Frameworks/Ruby.framework/Versions/Current/Ruby ruby_prof.bundle

        install_name_tool -change @executable_path/../Frameworks/Ruby.framework/Versions/Current/Ruby @executable_path/../Frameworks/Ruby.framework/Versions/Current/libruby.2.2.0.dylib ruby_prof.bundle 

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

Looks like it needs to match: RUBY_PLATFORM

SU2021.0: x86_64-darwin18
SU2020.0: x86_64-darwin
SU2019.0: x86_64-darwin
SU2018.0: x86_64-darwin14

spec = Gem::Specification.find_by_name('ruby-prof')
File.exist?(spec.gem_build_complete_path)

Gem::Platform.local.to_s

```
> RUBY_PLATFORM
x86_64-darwin18

> spec = Gem::Specification.find_by_name('ruby-prof')
#<Gem::Specification name=ruby-prof version=1.4.3>

> spec.gem_build_complete_path
/Users/tthomas2/Library/Application Support/SketchUp 2021/SketchUp/Gems/extensions/x86_64-darwin-18/2.7.0/ruby-prof-1.4.3/gem.build_complete

> Gem::Platform.local.to_s
x86_64-darwin-18

> spec.extensions
["ext/ruby_prof/extconf.rb"]

> spec.extension_dir
/Users/tthomas2/Library/Application Support/SketchUp 2021/SketchUp/Gems/extensions/x86_64-darwin-18/2.7.0/ruby-prof-1.4.3

> spec.require_paths
["/Users/tthomas2/Library/Application Support/SketchUp 2021/SketchUp/Gems/extensions/x86_64-darwin-18/2.7.0/ruby-prof-1.4.3", "lib"]

> spec.base_dir
/Users/tthomas2/Library/Application Support/SketchUp 2021/SketchUp/Gems
```

https://stackoverflow.com/a/2164689/486990


/Applications/SketchUp 2018/SketchUp.app/Contents/Frameworks
/Applications/SketchUp 2019/SketchUp.app/Contents/Frameworks

VT:
SU2019: @executable_path/../Frameworks/Ruby.framework/Versions/Current/Ruby
SU2018: @executable_path/../Frameworks/Ruby.framework/Versions/Current/libruby.2.2.0.dylib