require 'set'

require 'speedup/callstack_printer'
require 'speedup/profile_test'


module SpeedUp

  def self.profile(&block)
    unless defined?(RubyProf)
      message = 'RubyProf not loaded. Please run Extensions > SpeedUp > Setup'
      UI.messagebox(message)
    end

    Sketchup.status_text = "Profiling..."
    # trace_file = File.join(Sketchup.temp_dir, 'profup-graph.html')
    # ENV['RUBY_PROF_TRACE'] = trace_file
    # RubyProf.exclude_threads = Thread.list.select{ |t| t != Thread.current }
    options = {
      # include_threads: [Thread.current],
      merge_fibers: true
    }
    profiler = RubyProf::Profile.new(options)
    # Eliminate SpeedUp.profile appearing at the top of the call stack.
    profiler.exclude_singleton_methods!(SpeedUp, :profile)
    begin
      profiler.start
      yield
    ensure
      result = profiler.stop
    end

    Sketchup.status_text = "Generating graph report..."
    graph_report = File.join(Sketchup.temp_dir, 'profup-graph.html')
    File.open(graph_report, 'w') { |file|
      printer = RubyProf::GraphHtmlPrinter.new(result)
      printer.print(file)
    }

    Sketchup.status_text = "Generating callstack report..."
    callstack_report = File.join(Sketchup.temp_dir, 'profup-callstack.html')
    File.open(callstack_report, 'w') { |file|
      printer = CallStackPrinter.new(result)
      printer.print(file)
    }

    Sketchup.status_text = "Profiling done!"
    jquery = File.join(__dir__, "js", "jquery.js")
    html = <<-EOT
    <!DOCTYPE html>
    <html>
    <head>
      <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
      <script src="#{jquery}"></script>
      <script>
      $(document).ready(function() {
        $('#graph').ready(function() {
          var frame_graph = $("#graph")[0];
          var $graph = $(frame_graph.contentDocument);
          $graph.find("a[href^='file']").on('click', function() {
            window.location = "skp:file@" + this.href
            return false;
          });
        });

        $('#callstack').ready(function() {
          var frame_callstack = $("#callstack")[0];
          var $callstack = $(frame_callstack.contentDocument);
          $callstack.find("a[href^='file']").on('click', function() {
            window.location = "skp:file@" + this.href
            return false;
          });
        });

      });
      </script>
    </head>
    <frameset cols="60%, 40%">
      <frame src="#{graph_report}" name="graph" id="graph">
      <frame src="#{callstack_report}" name="callstack" id="callstack">
    </frameset>
    </html>
    EOT

    report = File.join(Sketchup.temp_dir, 'profup-report.html')
    File.open(report, 'w') { |file|
      file.puts html
    }

    options = {
      :dialog_title => "Profiling Results",
      :preferences_key => 'SpeedUpProfiling',
      :scrollable => true,
      :resizable => true,
      :height => 400,
      :width => 600,
      :left => 200,
      :top => 200
    }
    @windows ||= Set.new
    window = UI::WebDialog.new(options)
    window.add_action_callback("file") { |dialog, params|
      puts "Callback('file'): #{params}"
      if params.include?('<main>')
        puts "Evaluated content. Cannot open file."
      else
        file_and_line = params.gsub("file:///", "")
        puts file_and_line
        filename, line_number = file_and_line.split('#')
        puts filename
        puts line_number
        editor = "C:/Program Files/Sublime Text 3/sublime_text.exe"
        command = %["#{editor}" "#{filename}:#{line_number}"]
        puts command
        system(command)
      end
    }
    window.set_on_close {
      # Allow window to be garbage collected.
      @windows.delete(window)
      window = nil
    }
    window.set_file(report)
    window.show
    @windows << window
  end

end # module
