begin
  gem 'benchmark'
rescue LoadError => error
  puts 'Warning: SpeedUp was unable to activate the benchmark gem.'
end
require 'benchmark'
require 'benchmark/version'
puts "Loaded Benchmark #{Benchmark::VERSION}"

require 'stringio'

module SpeedUp

  class ProfileTest

    def self.test_name
      self.name.split('::').last.match(/(?:PR_)?(.+)/)[1]
    end

    # TODO: Move to separate file.
    # https://stackoverflow.com/a/4079031/486990
    module NaturalSort
      def self.sort(enumerable)
        enumerable.sort_by { |item| self.naturalized(item) }
      end
      def self.naturalized(item)
        string = item.to_s
        string.scan(/[^\d\.]+|[\d\.]+/).collect { |f| f.match(/\d+(\.\d+)?/) ? f.to_f : f }
      end
    end # module

    def self.tests
      profile_tests = public_instance_methods(true).grep(/^profile_/i).sort
      NaturalSort.sort(profile_tests)
    end

    def self.each_test_with_name(&block)
      self.tests.each { |method|
        name = method.to_s.match(/profile_(.+)/)[1]
        name.tr!('_', ' ')
        yield(method, name)
      }
    end

    def self.reload
      original_verbose = $VERBOSE
      random_profile_method = self.instance_methods.grep(/^profile_/).first
      path = self.instance_method(random_profile_method).source_location.first
      $VERBOSE = nil
      load path
    ensure
      $VERBOSE = original_verbose
    end

    # TODO: https://stackoverflow.com/questions/5881474/before-after-suite-when-using-ruby-minitest

    # TODO: Reload profile test files.

    def self.run(profile_method)
      self.reload
      GC.start # Try to make garbage collection a bit more predictable
      instance = self.new
      instance.send(:setup_testcase)
      instance.send(:setup)
      SpeedUp.profile do
        instance.send(profile_method)
      end
      instance.send(:teardown)
      instance.send(:teardown_testcase)
    end

    def self.benchmark
      self.reload
      instance = self.new
      label_size = tests.map { |t| t.to_s.size }.max
      instance.send(:setup_testcase)
      Benchmark.bm(label_size) do |x|
        self.each_test_with_name { |method, name|
          GC.start # Try to make garbage collection a bit more predictable
          instance.send(:setup)
          x.report(name) { instance.send(method) }
          instance.send(:teardown)
        }
      end
      instance.send(:teardown_testcase)
    end

    def self.redirect_stdout
      original_stdout = $stdout
      captured_output = StringIO.new
      $stdout = captured_output
      yield
      captured_output
    ensure
      $stdout = original_stdout
    end

    OUTPUT_REGEX = /(.+?)([0-9.]+)\s+([0-9.]+)\s+([0-9.]+)\s+\(\s*([0-9.]+)/

    def self.benchmark_average(iterations: 3)
      self.reload
      instance = self.new
      label_size = tests.map { |t| t.to_s.size }.max
      outputs = []
      # TODO: Allow the test-runner to adjust this.
      if instance.respond_to?(:benchmark_iterations)
        iterations = instance.send(:benchmark_iterations)
      end
      puts "Benchmarking #{instance.class.test_name} (#{iterations} iterations)..."
      iterations.times do |i|
        instance.send(:setup_testcase)
        output = redirect_stdout do
          Benchmark.bm(label_size) do |x|
            self.each_test_with_name { |method, name|
              GC.start # Try to make garbage collection a bit more predictable
              instance.send(:setup)
              x.report(name) { instance.send(method) }
              instance.send(:teardown)
            }
          end
        end
        outputs << output.string
        # puts "output: #{outputs.last.size}"
        # puts "---"
        # puts outputs.last
        # puts "---"
      end

      results = {}
      outputs.each { |output|
        matches = output.scan(OUTPUT_REGEX)
        matches.each { |match|
          name, *timing = match
          name.strip!
          timing.map!(&:to_f)
          results[name] ||= []
          results[name] << timing
          # p timing
        }
      }

      results.each { |name, timings|
        puts "============================================="
        puts name
        puts Benchmark::CAPTION
        timings.each { |timing|
          printf("%10.6f %10.6f %10.6f (%10.6f)\n", *timing)
        }
        rows = timings.transpose

        puts "---------------------------------------------"
        puts "min/max"
        mins = rows.map(&:min)
        maxs = rows.map(&:max)
        printf("%10.6f %10.6f %10.6f (%10.6f)\n", *mins)
        printf("%10.6f %10.6f %10.6f (%10.6f)\n", *maxs)

        puts "---------------------------------------------"
        puts "mean average"
        means = rows.map { |row| row.sum / row.size.to_f }
        printf("%10.6f %10.6f %10.6f (%10.6f)\n", *means)

        puts "---------------------------------------------"
        puts "standard deviance"
        # https://www.mathsisfun.com/data/standard-deviation.html
        variances = rows.map { |row|
          mean = row.sum / row.size.to_f
          squared_diffs = row.map { |n| (n - mean)**2 }
          squared_diffs.sum / squared_diffs.size.to_f
        }
        std_deviations = variances.map { |n| Math.sqrt(n) }
        printf("%10.6f %10.6f %10.6f (%10.6f)\n", *std_deviations)
      }

      instance.send(:teardown_testcase)
    end

    def setup; end
    def teardown; end

    def setup_testcase; end
    def teardown_testcase; end

  end # class

end # module
