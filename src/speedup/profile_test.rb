require "benchmark"


module SpeedUp

  class ProfileTest

    def self.test_name
      self.name.split("::").last.match(/(?:PR_)?(.+)/)[1]
    end

    def self.tests
      public_instance_methods(true).grep(/^profile_/i).sort
    end

    def self.each_test_with_name(&block)
      self.tests.each { |method|
        name = method.to_s.match(/profile_(.+)/)[1]
        name.tr!("_", " ")
        yield(method, name)
      }
    end

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
      Benchmark.bm(label_size) do |x|
        self.each_test_with_name { |method, name|
          instance.send(:setup)
          x.report(name)   { instance.send(method) }
          instance.send(:teardown)
        }
      end
    end

    def setup; end
    def teardown; end

  end # class

end # module
