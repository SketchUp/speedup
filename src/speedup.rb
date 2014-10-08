gem "ruby-prof"
require "ruby-prof"

require "benchmark"
require "set"
require "stringio"


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


  def self.profile(&block)
    Sketchup.status_text = "Profiling..."
    result = RubyProf.profile do
      yield
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
        //alert('ready');

        $('#graph').ready(function() {
          //alert('graph load');

          // .contents() doesn't appear to work in this case...

          var frame_graph = $("#graph")[0];
          var $graph = $(frame_graph.contentDocument);
          //$graph.find("a").css("background-color", "#BADA55");
          //$graph.find("a[href^='file']").css("background-color", "#a66");
          $graph.find("a[href^='file']").on('click', function() {
            //alert(decodeURI(this.href));
            window.location = "skp:file@" + this.href
            return false;
          });
        });

        $('#callstack').ready(function() {
          //alert('callstack load');

          // .contents() doesn't appear to work in this case...

          var frame_callstack = $("#callstack")[0];
          var $callstack = $(frame_callstack.contentDocument);
          //$callstack.find("a").css("background-color", "#BADA55");
          //$callstack.find("a[href^='file']").css("background-color", "#a66");
          $callstack.find("a[href^='file']").on('click', function() {
            //alert(decodeURI(this.href));
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
