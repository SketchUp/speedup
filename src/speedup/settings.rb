module SpeedUp

  # @param [String] key
  # @param [Object] default
  # @return [Object]
  def self.read_setting(key, default = nil)
    Sketchup.read_default(EXTENSION[:product_id], key, default)
  end

  # @param [String] key
  # @param [Object] value
  def self.write_setting(key, value)
    Sketchup.write_default(EXTENSION[:product_id], key, value)
  end


  def self.toggle_verbose
    self.verbose = !self.verbose?
  end

  def self.verbose?
    self.read_setting('verbose', true)
  end

  # @param [Boolean] value
  def self.verbose=(value)
    self.write_setting('verbose', value)
  end


  def self.toggle_noop
    self.noop = !self.noop?
  end

  def self.noop?
    self.read_setting('noop', false)
  end

  # @param [Boolean] value
  def self.noop=(value)
    self.write_setting('noop', value)
  end


  def self.toggle_ruby_prof_loading
    self.load_ruby_prof = !self.load_ruby_prof?
  end

  def self.load_ruby_prof?
    self.read_setting('load_ruby_prof', true)
  end

  # @param [Boolean] value
  def self.load_ruby_prof=(value)
    self.write_setting('load_ruby_prof', value)
  end

end # module
