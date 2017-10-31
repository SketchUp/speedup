begin
  gem 'ruby-prof'
  require "ruby-prof"
rescue LoadError => error
  puts 'SpeedUp was unable to load ruby-prof'
end

require 'sketchup.rb'


module SpeedUp

  require 'speedup/setup'
  require 'speedup/discoverer'

  if defined?(RubyProf)
    require 'speedup/runner'
  end


  unless file_loaded?(__FILE__)
    menu = UI.menu('Plugins').add_submenu('SpeedUp')

    id = menu.add_item('Setup') {
      self.setup
    }
    menu.set_validation_proc(id) {
      self.setup? ? MF_GRAYED : MF_ENABLED
    }

    file_loaded(__FILE__)
  end

end # module
