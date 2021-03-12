require 'sketchup.rb'

module SpeedUp

  require 'speedup/vendor'
  require 'speedup/discoverer'
  require 'speedup/settings'

  if self.load_ruby_prof?
    begin
      # begin
      #   gem 'ruby-prof' # Why are we doing this?
      # rescue LoadError => error
      #   puts 'Warning: SpeedUp was unable to activate the ruby-prof gem.'
      # end
      require "ruby-prof"
      puts "SpeedUp loaded RubyProf #{RubyProf::VERSION}" if self.verbose?
    rescue LoadError => error
      puts 'Warning: SpeedUp was unable to load ruby-prof'
    end
  else
    puts "Note: SpeedUp did not load ruby-prof as this is suppressed by Develop settings."
  end

  # This must be done here after trying to load ruby-prof.
  require 'speedup/setup'
  if defined?(RubyProf)
    require 'speedup/runner'
  end

  # Only works for RB files - not scrambled RBS version.
  #
  # @example
  #   SpeedUp.reload
  #
  # @return [Integer]
  def self.reload
    original_verbose = $VERBOSE
    $VERBOSE = nil
    # Reload all the Ruby files.
    files = Dir.glob(File.join(PATH, '**/*.rb')).reject { |file|
      file.include?('precompiled-gems')
    }
    x = files.each { |file|
      load file
    }
    x.length
  ensure
    $VERBOSE = original_verbose
  end

  unless file_loaded?(__FILE__)
    menu = UI.menu('Plugins').add_submenu('SpeedUp')

    id = menu.add_item('Setup') {
      self.setup
    }
    menu.set_validation_proc(id) {
      !self.load_ruby_prof? || self.setup? ? MF_GRAYED : MF_ENABLED
    }

    develop_menu = menu.add_submenu('Develop')
    develop_menu.add_item('Vendor New RubyProf Version') {
      self.prompt_vendor_new_version_ui
    }

    develop_menu.add_separator

    develop_menu.add_item('Uninstall ruby-prof Gems') {
      self.remove_installed_ruby_prof_from_sketchup_ui
    }

    develop_menu.add_separator

    id = develop_menu.add_item("Load ruby-prof") {
      self.toggle_ruby_prof_loading
    }
    develop_menu.set_validation_proc(id) {
      self.load_ruby_prof? ? MF_CHECKED : MF_ENABLED
    }

    id = develop_menu.add_item("Verbose") {
      self.toggle_verbose
    }
    develop_menu.set_validation_proc(id) {
      self.verbose? ? MF_CHECKED : MF_ENABLED
    }

    id = develop_menu.add_item("Noop") {
      self.toggle_noop
    }
    develop_menu.set_validation_proc(id) {
      self.noop? ? MF_CHECKED : MF_ENABLED
    }

    file_loaded(__FILE__)
  end

end # module
