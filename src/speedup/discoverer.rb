require 'speedup/profile_test'


module SpeedUp

  # @param [Sketchup::Menu] menu
  # @param [Class, Module] namespace
  # @return [nil]
  def self.build_menus(menu, namespace)
    profile_klasses = self.discover_profile_classes(namespace)
    profile_klasses.each { |profile_klass|
      klass_menu = menu.add_submenu(profile_klass.test_name)
      klass_menu.add_item('Benchmark') { profile_klass.benchmark }
      klass_menu.add_separator
      profile_instance = profile_klass.new
      profile_klass.each_test_with_name { |method, name|
        klass_menu.add_item(name) { profile_klass.run(method) }
      }
    }
    nil
  end

  # @param [Class, Module] namespace
  # @return [Array<SpeedUp::ProfileTest>]
  def self.discover_profile_classes(namespace)
    consts = namespace.constants.map { |const|
      namespace.const_get(const)
    }
    klasses = consts.select { |object| object.class == Class }
    klasses.select { |klass|
      klass.ancestors.include?(SpeedUp::ProfileTest)
    }
  end

  # @param [String] path
  # @return [Array<String>]
  def self.load_profile_tests(path)
    pattern = "#{path}/**/PR_*.rb"
    Dir.glob(pattern) { |file| load file }
  end

end # module
