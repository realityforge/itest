module ITest
  class Config
    class << self
      attr_writer :reports_dir

      def reports_dir
        return @reports_dir unless @reports_dir.nil?
        return "#{RAILS_ROOT}/tmp/reports" if defined?(RAILS_ROOT)
        return "#{APP_ROOT}/tmp/reports" if defined?(APP_ROOT)
        raise "reports_dir not specified and unable to guess dir"
      end

      attr_writer :scripts_dir

      def scripts_dir
        return @scripts_dir unless @scripts_dir.nil?
        return "#{RAILS_ROOT}/tmp" if defined?(RAILS_ROOT)
        return "#{APP_ROOT}/tmp" if defined?(APP_ROOT)
        raise "scripts_dir not specified and unable to guess dir"
      end
    end
  end

  class TestTask
    attr_accessor :clobber_dir
    attr_accessor :namespace_key
    attr_accessor :description
    attr_writer :reports_dir
    attr_writer :script_filename

    attr_reader :test_key
    attr_reader :filelist
    attr_reader :target_dir

    def initialize(test_key, filelist)
      @test_key, @filelist = test_key, filelist
      @clobber_dir = true
      @namespace_key = :test
      yield self if block_given?
      return define
    end

    def reports_dir
      @reports_dir || "#{ITest::Config.reports_dir}/#{test_key}"
    end

    def script_filename
      @script_filename || "#{ITest::Config.scripts_dir}/test_#{test_key}_script.rb"
    end

    private

    def define
      namespace self.namespace_key do
        desc self.description || "Run the #{self.test_key} tests."
        return task(self.test_key) do
          test_script_filename = self.script_filename
          test_reports_dir = self.reports_dir
          FileUtils.rm_rf(test_reports_dir) if self.clobber_dir
          FileUtils.mkdir_p test_reports_dir
          File.open( test_script_filename, "w" ) do |f|
            f.write <<HEADER
      require 'java'
      ENV["CI_REPORTS"] = '#{test_reports_dir}';
      begin;
        require 'rubygems';
        gem 'ci_reporter';
        require 'ci/reporter/rake/test_unit_loader.rb';
      rescue LoadError;
        puts "The ci_reporter gem is not available. Reports will not be generated."
      end;
HEADER
            test_content = self.filelist.collect do |filename|
              "require '#{filename}';"
            end.join("\n")
            f.write test_content
          end
          ruby test_script_filename
        end
      end
    end
  end
end