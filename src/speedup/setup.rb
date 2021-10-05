require 'fileutils'

require 'sketchup.rb'


module SpeedUp

  POINTER_SIZE = ['a'].pack('P').size * 8

  def self.setup
    SKETCHUP_CONSOLE.show

    puts 'Setting up SpeedUp...'

    puts 'Updating Benchmark from gem...'

    Gem.install('benchmark')
    gem 'benchmark'

    puts 'Installing pre-compiled rubo-prof...'

    puts '> Checking for compatible version...'
    precompiled_path = File.join(__dir__, 'precompiled-gems')
    ruby_version = RUBY_VERSION.split('.')[0, 2].join
    ruby_path = File.join(precompiled_path, "Ruby#{ruby_version}")
    platform = Sketchup.platform == :platform_win ? 'win' : 'mac'
    gems_folder_name = if Sketchup.platform == :platform_win
      "Gems#{POINTER_SIZE}"
    else
      "Gems"
    end
    gems_source = File.join(ruby_path, platform, gems_folder_name)
    puts "> Source: #{gems_source} (Exists: #{File.exists?(gems_source)})"

    destination = Gem.dir
    puts "> Target: #{destination} (Exists: #{File.exists?(destination)})"

    puts '> Installing...'
    Sketchup::Console.send(:public, :puts)
    FileUtils.copy_entry(gems_source, destination, preserve = false)

    begin
      puts '> Loading...'
      Gem.clear_paths # Why are we doing this?
      gem 'ruby-prof' # ...and this?
      require 'ruby-prof'
      require 'speedup/runner'
    ensure
      puts 'Done! (You may have to restart SketchUp)'
    end

    @setup_done = !defined?(RubyProf).nil?
  end


  def self.setup?
    @setup_done == true
  end


  @setup_done = !defined?(RubyProf).nil?

end # module
