require 'speedup/settings'

require 'fileutils'
require 'pathname'

module SpeedUp

  def self.prompt_vendor_new_version_ui
    self.prompt_vendor_new_version(verbose: self.verbose?, noop: self.noop?)
  end

  # SpeedUp.prompt_vendor_new_version
  # SpeedUp.prompt_vendor_new_version(verbose: true)
  # SpeedUp.prompt_vendor_new_version(verbose: true, noop: true)
  def self.prompt_vendor_new_version(verbose: false, noop: false)
    unless self.is_run_from_git_repo?
      message = "To vendor a new ruby-gem version SpeedUp must be run from the git repository."
      UI.messagebox(message)
      return nil
    end

    default_directory = self.read_setting('ruby_directory', 'C:/Ruby27-x64/')

    ruby_directory = UI.select_directory(
      title: "Select Ruby installation directory",
      directory: default_directory
    )
    return nil if ruby_directory.nil?

    self.write_setting('ruby_directory', ruby_directory)

    ruby_executable = File.join(ruby_directory, 'bin', 'ruby.exe')
    unless File.exist?(ruby_executable)
      UI.messagebox("Unable to identify Ruby installation at: #{ruby_directory}")
      return nil
    end

    puts "Vendoring ruby-prof into SpeedUp..." if verbose

    gems = self.find_installed_ruby_gems(ruby_directory)
    gems.sort!

    default_gem_name = gems.max.name
    gem_names = gems.map(&:name).join("|")

    prompts = ["Version"]
    defaults = [default_gem_name]
    list = [gem_names]
    response = UI.inputbox(prompts, defaults, list, "Choose RubyProf Version")
    return unless response

    name = response[0]
    ruby_prof_gem = gems.find { |gem| gem.name == name }

    begin
      begin
        self.vendor_new_version(ruby_directory, ruby_prof_gem,
          verbose: verbose,
          noop: noop
        )
      rescue GemAlreadyInstalled
        message = "#{ruby_prof_gem.name} is already vendored into SpeedUp. Remove existing version and install new?"
        response = UI.messagebox(message, MB_YESNO)
        return nil if IDNO

        self.vendor_new_version(ruby_directory, ruby_prof_gem,
          override_existing: true,
          verbose: verbose,
          noop: noop
        )
      end
    rescue GemInstallationFailed => error
      puts "Error: #{error.message}" if verbose
      UI.messagebox(error.message)
      return nil
    end

    message = 'New ruby-prof version vendored into SpeedUp. Manually verify and prune '\
      'redundant files. (bin, ext for example, as well as binaries unrelated to target '\
      'SketchUp version).'
    UI.messagebox(message)

    nil
  end

  RubyProfGem = Struct.new(:gemspec, :gem_dir, :version, :name) do
    def <=>(other)
      self.version <=> other.version
    end
  end

  RUBY_PROF_GEMSPEC_VERSION_PATTERN = /ruby-prof-(\d+\.\d+\.\d+).*\.gemspec$/

  # @param [String] ruby_directory
  def self.find_installed_ruby_gems(ruby_directory)
    # C:\Ruby27-x64\lib\ruby\gems\2.7.0\cache\ruby-prof-1.4.3-x64-mingw32.gem
    # C:\Ruby27-x64\lib\ruby\gems\2.7.0\gems\ruby-prof-1.4.3-x64-mingw32\lib\2.7
    # C:\Ruby27-x64\lib\ruby\gems\2.7.0\specifications\ruby-prof-1.4.3-x64-mingw32.gemspec

    pattern = "#{ruby_directory}/lib/ruby/gems/*/specifications/ruby-prof-*.gemspec"
    ruby_prof_spec_paths = Dir.glob(pattern)

    ruby_prof_specs = ruby_prof_spec_paths.map { |path|
      version = path.match(RUBY_PROF_GEMSPEC_VERSION_PATTERN).captures.first
      name = File.basename(path.to_s, '.*')
      spec_file = Pathname.new(path)
      gem_dir = spec_file.parent.parent.join('gems', name)

      raise "spec_file not found: #{spec_file}" unless spec_file.exist?
      raise "gem_dir not found: #{gem_dir}" unless gem_dir.exist?

      RubyProfGem.new(spec_file, gem_dir, version, name)
    }

    ruby_prof_specs
  end

  class GemAlreadyInstalled < StandardError; end
  class GemInstallationFailed < StandardError; end
  class GemUninstallationFailed < StandardError; end

  # @param [String] ruby_directory
  # @param [RubyProfGem] ruby_prof_gem
  #
  # @raises [GemAlreadyInstalled]
  def self.vendor_new_version(ruby_directory, ruby_prof_gem,
      override_existing: false,
      noop: false,
      verbose: false)
    puts "ruby_directory: #{ruby_directory}" if verbose
    puts "ruby_prof_gem: #{ruby_prof_gem}" if verbose

    ruby_version = RUBY_VERSION.split('.')
    ruby_name = "Ruby#{ruby_version[0]}#{ruby_version[1]}"
    vendor_path = Pathname.new(__dir__).join('precompiled-gems', ruby_name, 'Gems64')
    puts "vendor_path: #{vendor_path}" if verbose
    vendor_path.mkpath unless noop

    vendor_gem_specs_dir = vendor_path.join('specifications')
    vendor_gem_dir = vendor_path.join('gems')
    vendor_gem_specs_dir.mkpath unless noop
    vendor_gem_dir.mkpath unless noop
    puts "vendor_gem_specs_dir: #{vendor_gem_specs_dir} (Exists: #{vendor_gem_specs_dir.exist?})" if verbose
    puts "vendor_gem_dir: #{vendor_gem_dir} (Exists: #{vendor_gem_dir.exist?})" if verbose

    target_gem_spec = vendor_gem_specs_dir.join(ruby_prof_gem.gemspec.basename)
    target_gem_dir = vendor_gem_dir.join(ruby_prof_gem.gem_dir.basename)
    puts "target_gem_spec: #{target_gem_spec} (Exists: #{target_gem_spec.exist?})" if verbose
    puts "target_gem_dir: #{target_gem_dir} (Exists: #{target_gem_dir.exist?})" if verbose

    # if !noop && !override_existing && (target_gem_spec.exist? || target_gem_dir.exist?)
    #   raise GemAlreadyInstalled
    # end
    if target_gem_spec.exist? || target_gem_dir.exist?
      if override_existing
        puts "Removing existing gem..." if verbose
        unless noop
          target_gem_spec.delete if target_gem_spec.exist?
          target_gem_dir.rmtree if target_gem_dir.exist?
        end
        if target_gem_spec.file?
          raise GemInstallationFailed, "Unable to remove #{target_gem_spec}."
        end
        if target_gem_dir.directory?
          raise GemInstallationFailed, "Unable to remove #{target_gem_dir}."
        end
      else
        raise GemAlreadyInstalled
      end
    end

    puts "Installing gem..." if verbose
    unless noop
      FileUtils.copy_entry(ruby_prof_gem.gemspec.to_s, target_gem_spec.to_s)
      FileUtils.copy_entry(ruby_prof_gem.gem_dir.to_s, target_gem_dir.to_s)

      unless target_gem_spec.file?
        raise GemInstallationFailed, "#{target_gem_spec} was not installed."
      end
      unless target_gem_dir.directory?
        raise GemInstallationFailed, "#{target_gem_dir} was not installed."
      end
    end

    puts "#{ruby_prof_gem.name} installed in SketchUp's gem directory." if verbose

    nil
  end

  def self.remove_installed_ruby_prof_from_sketchup_ui
    self.remove_installed_ruby_prof_from_sketchup(verbose: self.verbose?, noop: self.noop?)
  end

  def self.remove_installed_ruby_prof_from_sketchup(verbose: false, noop: false)
    message = "Uninstall all ruby-prof gems installed in you SketchUp Gems directory?"
    response = UI.messagebox(message, MB_OKCANCEL)
    return nil if response == IDCANCEL

    if Sketchup.platform == :platform_win && self.load_ruby_prof?
      message = "SpeedUp might not be able to uninstall all versions of ruby-prof "\
        "if it's already loaded. You might have to disable loading of ruby-prof "\
        "and restart SketchUp.\n\nContinue?"
      response = UI.messagebox(message, MB_OKCANCEL)
      return nil if response == IDCANCEL
    end

    # C:/Users/tthomas2/AppData/Roaming/SketchUp/SketchUp 2021/SketchUp/Plugins
    # C:/Users/tthomas2/AppData/Roaming/SketchUp/SketchUp 2021/SketchUp/Gems64/spesifications/ruby-prof-1.4.2-x64-mingw32.gemspec
    # C:/Users/tthomas2/AppData/Roaming/SketchUp/SketchUp 2021/SketchUp/Gems64/gems/ruby-prof-1.4.2-x64-mingw32
    plugins_dir = Pathname.new(Sketchup.find_support_file('Plugins'))
    sketchup_app_dir = plugins_dir.parent
    sketchup_gems_root_dir = sketchup_app_dir.join('Gems64')
    sketchup_gem_specs_dir = sketchup_gems_root_dir.join('specifications')
    sketchup_gem_dir = sketchup_gems_root_dir.join('gems')
    puts "sketchup_gem_specs_dir: #{sketchup_gem_specs_dir} (Exists: #{sketchup_gem_specs_dir.exist?})" if verbose
    puts "sketchup_gem_dir: #{sketchup_gem_dir} (Exists: #{sketchup_gem_dir.exist?})" if verbose

    uninstalled = []
    failed = []

    pattern = "#{sketchup_gem_specs_dir}/ruby-prof-*.gemspec"
    Dir.glob(pattern) do |path|
      spec_path = Pathname.new(path)
      begin
        uninstalled << self.uninstall_gem_from_sketchup(spec_path: spec_path, verbose: verbose, noop: noop)
      rescue GemUninstallationFailed => error
        failed << error.message
        next
      end
    end

    # In case there are orphan ruby-spec gem directories.
    pattern = "#{sketchup_gem_dir}/ruby-prof-*"
    Dir.glob(pattern) do |path|
      path = Pathname.new(path)
      begin
        uninstalled << self.uninstall_gem_from_sketchup(gem_path: path, verbose: verbose, noop: noop)
      rescue GemUninstallationFailed => error
        failed << error.message
        next
      end
    end

    unless failed.empty?
      message = "Errors while uninstalling:\n\n#{failed.join("\n")}"
      UI.messagebox(message)
    end

    unless uninstalled.empty?
      message = "Uninstalled the following ruby-prof versions:\n\n#{uninstalled.join("\n")}"
      UI.messagebox(message)
    end

    if uninstalled.empty? && failed.empty?
      UI.messagebox("No ruby-prof versions where found.")
    end
    nil
  end

  def self.uninstall_gem_from_sketchup(spec_path: nil, gem_path: nil, verbose: false, noop: false)
    puts "spec_path: #{spec_path}" if verbose
    puts "gem_path: #{gem_path}" if verbose
    raise "must provide spec_path or gem_path" if spec_path.nil? && gem_path.nil?

    if spec_path
      gem_name = File.basename(spec_path.to_s, '.*')
      gem_dir = spec_path.parent.parent.join('gems', gem_name)
    else
      gem_name = gem_path.basename
      gem_dir = gem_path
    end
    puts "Uninstalling #{gem_name} from SketchUp gems..." if verbose

    unless noop
      spec_path.delete if spec_path && spec_path.exist?
      gem_dir.rmtree if gem_dir.exist?
      if spec_path && spec_path.file?
        raise GemUninstallationFailed, "Unable to remove #{spec_path}."
      end
      if gem_dir.directory?
        raise GemUninstallationFailed, "Unable to remove #{gem_dir}."
      end
    end

    gem_name
  end

  def self.is_run_from_git_repo?
    extension_dir = Pathname.new(__dir__)
    git_dir = extension_dir.join('..', '..', '.git').expand_path
    git_dir.directory?
  end

end # module
