# Building/Installing RubyProf

The earlier versions of ruby-prof had to be built on installation. On Windows
this is a challenge because it doesn't have a compiler available on the system
by default.

After SU2017 we also had to hack ruby-prof to only sample the main thread in
order to get usable results. (Might have been issues with Chromium and it's
threads and processed?) This was with the 0.17 and earlier versions.

Fortunately, with 1.4+ this is no longer needed. ruby-prof also started to
bundle pre-built binaries that made things easier as a compiler wouldn't be
needed. However, since we maintain tools for older SketchUp versions with
older versions we still might need to build them. For instance, 1.4.3 shipped
with binaries for Ruby 2.7 and 3.0 only. Ruby 2.5 was no longer maintained, but
it still worked with 2.5.

Because it can be a hassle to get this gem to work we bundle it with SpeedUp.

Users can install it by `SpeedUp > Setup`.

## Vendor new version of RubyProf into SpeedUp

### Requirements

1. Standalone version of Ruby, matching version of SketchUp.
2. Ruby DevKit (Windows)
3. Bundler

### Installing to Standalone Ruby

First ensure you have activated the appropriate Ruby version:

#### Windows

    SET PATH=c:\Ruby27-x64\bin;%PATH%
    c:\RubyDevKit64\devkitvars.bat

TODO(thomthom): Is `c:\RubyDevKit64\devkitvars.bat` needed if installing via
`gem install`? Or only when trying to build the gem from source?

##### macOS

Use RVM on macOS to install and manage Ruby installations.

    rvm use 2.7

#### Installation

"Typical" installation:

```
gem install ruby-prof
```

For Windows when RubyProf doesn't offer a pre-built gem for that target Ruby
version:

```
gem install ruby-prof --platform ruby
```

If you run into errors, check if they are mentioned in this thread: https://github.com/ruby-prof/ruby-prof/issues/301

### Vendoring into SpeedUp

1. Uncheck `SpeedUp > Develop > Load ruby-prof`
1. Restart SketchUp (Ensuring ruby-prof isn't loaded and locking any files)
1. `SpeedUp > Develop > Uninstall ruby-prof Gems` This removes old ruby-prof versions from SketchUp's gem directory.
1. Restart SketchUp (Ensuring that Ruby knows the gems are removed)
1. `SpeedUp > Develop > Vendor New RubyProof Version` (Follow instructions)
1. Check `SpeedUp > Develop > Load ruby-prof`
1. Restart SketchUp (Makes Ruby pick up the new version so it can be tested that everything works)

## Debugging

To trace what RubyProf do, use the `RUBY_PROF_TRACE` environment variable:

    ENV['RUBY_PROF_TRACE'] = "#{ENV['HOME']}\Desktop\trace16.log"
    ENV['RUBY_PROF_TRACE'] = "#{ENV['HOME']}\Desktop\trace17.log"

## Mac Builds

This is being done by `vendor.rb`, but leaving information here as well to
document some of the unexpected quirks in making this work.

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
