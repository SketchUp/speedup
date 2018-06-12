require 'speedup/profile_test'


module SpeedUp
  class Benchmarker

    def initialize(namespace, profile_tests_path)
      @namespace = namespace
      @path = profile_tests_path
    end

    def show
      self.load_profile_tests(@path)
      profile_klasses = self.discover_profile_classes(@namespace)
      dialog = BenchmarkDialog.new(profile_klasses)
      dialog.show
    end

  end
end # module
