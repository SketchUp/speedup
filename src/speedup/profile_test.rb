require 'benchmark'


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

    # TODO: https://stackoverflow.com/questions/5881474/before-after-suite-when-using-ruby-minitest

    def self.run(profile_method)
      instance = self.new
      instance.send(:setup)
      SpeedUp.profile do
        instance.send(profile_method)
      end
      instance.send(:teardown)
    end

    def self.benchmark
      instance = self.new
      label_size = tests.map { |t| t.to_s.size }.max
      instance.send(:setup_testcase)
      Benchmark.bm(label_size) do |x|
        self.each_test_with_name { |method, name|
          instance.send(:setup)
          x.report(name) { instance.send(method) }
          instance.send(:teardown)
        }
      end
      instance.send(:teardown_testcase)
    end

    def setup; end
    def teardown; end

    def setup_testcase; end
    def teardown_testcase; end

  end # class

end # module
