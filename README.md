# RubyProf wrapper for SketchUp

**NOTE: This is work in process. Early stages and things will change.**

This is a profiling tool for SketchUp Ruby extensions. It wraps [`Benchmark`](https://ruby-doc.org/stdlib-2.2.4/libdoc/benchmark/rdoc/Benchmark.html) and the [`RubyProf`](https://github.com/ruby-prof/ruby-prof) gem.

**Profiling**

![Profiling in SketchUp](docs/images/profiling.png)

**Benchmarking**

![Benchmarking in SketchUp](docs/images/benchmarking.png)

## Setup

### Windows

[RubyProf](https://github.com/ruby-prof/ruby-prof) is a gem that needs to be compiled as it's installed. This prevents it from being installed from within SketchUp under Windows. To compile gems you need the [Ruby DevKit](https://rubyinstaller.org/add-ons/devkit.html) to be configured for the compiler.

Additionally the gem started misbehaving in SketchUp 2017 and up. The profiler isn't able to display the results correctly, thinking there are more threads running. A workaround has been to hack the gem into being single threaded: https://github.com/thomthom/ruby-prof/

To make it easier for SketchUp extension developers this extension bundles pre-compiled versions of RubyProf and will attempt to install it into SketchUp's gems directory.

`Extensions > SpeedUp > Setup`

### OSX

This extension have not been tested under OSX. It does not contain pre-compiled gems for RubyProf for OSX.

Maybe `Gem.install('ruby-prof')` will work.

## Creating performance tests

### Benchmarking

TODO: Refactor how benchmark tests are discovered and menus created.

![Benchmarking in SketchUp](docs/images/benchmarking-menu.png)

### Profiling

Similar to how you create test units using `Minitest` (Or [TestUp](https://github.com/SketchUp/testup-2) tests), you create profile tests by inheriting from `SpeedUp::ProfileTest`.

**Example profile test case**

```ruby
require 'speedup.rb'

module Example
  module Profiling
    class PR_ShadowRender < SpeedUp::ProfileTest

      def setup
        # Setup code here. This is run before every test.
      end

      def teardown
        # Teardown code here. This is run after every test.
      end

      # Any method starting will "profile_" will be treated as a profile
      # test.

      def profile_render_to_face_8x8x1
        # Code you want to profile here.
      end

      def profile_render_to_face_8x8x2
        # Code you want to profile here.
      end

      def profile_render_to_face_32x32x2
        # Code you want to profile here.
      end

    end # class
  end # module
end # module
```

```ruby
module Example
  menu = UI.menu('Plugins').add_submenu('Example')
  menu_profile = menu.add_submenu('Profile')
  # This line will scan the Example::Profiling module for
  # `SpeedUp::ProfileTest` derived classes and build menus for them.
  SpeedUp.build_menus(menu_profile, Example::Profiling)
end # module
```

Full example: https://github.com/thomthom/shadow-texture/blob/master/profiling/PR_ShadowRender.rb

![Profiling in SketchUp](docs/images/profiling-menu.png)
