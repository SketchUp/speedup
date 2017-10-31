module SpeedUp

  class CallStackPrinter < RubyProf::CallStackPrinter

    def print_header
      @output.puts "<html><head>"
      @output.puts '<meta http-equiv="X-UA-Compatible" content="IE=edge"/>'
      @output.puts '<meta http-equiv="content-type" content="text/html; charset=utf-8">'
      @output.puts "<title>#{h title}</title>"
      print_css
      print_java_script
      @output.puts '</head><body><div style="display: inline-block;">'
      print_title_bar
      print_commands
      print_help
    end

    def print_css
      super
      @output.puts <<-end_css
        <style type="text/css">
        body {
          font-family: sans-serif;
        }
        </style>
      end_css
    end

  end #class

end # module
