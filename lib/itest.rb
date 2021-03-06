module ITest
  class << self
    def define_test(pattern, options = {}, &block)
      buildr_project = options[:buildr_project]

      if buildr_project.nil? && Buildr.application.current_scope.size > 0
        buildr_project = Buildr.project(Buildr.application.current_scope.join(':')) rescue nil
      end

      build_key = options[:key] || (buildr_project.nil? ? :default : buildr_project.name.split(':').last)

      if pattern
        base_directory = File.dirname(Buildr.application.buildfile.to_s)
        pattern = File.expand_path(pattern, base_directory)
      end

      task = ITest::TestTask.new(build_key, FileList[pattern], &block)

      buildr_project.test do
        begin
          task(task.task_name).invoke
        rescue
          raise unless Buildr.options.test == :all
        end
      end if buildr_project

      task
    end
  end

  class Config
    class << self
      attr_writer :reports_dir

      def reports_dir
        @reports_dir || "#{base_directory}/reports"
      end

      attr_writer :scripts_dir

      def scripts_dir
        @scripts_dir || "#{base_directory}/target"
      end

      def base_directory
        return RAILS_ROOT if defined?(RAILS_ROOT)
        return APP_ROOT if defined?(APP_ROOT)
        return File.dirname(Buildr.application.buildfile.to_s) if defined?(Buildr)
        raise 'Unable to derive base_directory. Need to explicity specify directories.'
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

    attr_reader :task_name

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

    include Rake::DSL

    def define
      namespace self.namespace_key do
        desc self.description || "Run the #{self.test_key} tests."
        t = task(self.test_key) do
          test_script_filename = self.script_filename
          FileUtils.mkdir_p File.dirname(test_script_filename)
          test_reports_dir = self.reports_dir
          FileUtils.rm_rf(test_reports_dir) if self.clobber_dir
          FileUtils.mkdir_p test_reports_dir
          File.open(test_script_filename, "w") do |f|
            f.write <<HEADER
require 'java'
ENV['CI_REPORTS'] = '#{test_reports_dir}';
ENV['DATABASE_YML'] = '#{ENV['DATABASE_YML'] || 'config/database.yml'}';
require 'rake'
require 'ci/reporter/rake/test_unit_loader.rb';
HEADER
            test_content = self.filelist.collect do |filename|
              "require '#{filename}';"
            end.join("\n")
            f.write test_content
            f.write "\n"
          end
          ruby_command = Util.win_os? ? 'jruby' : 'ruby'
          sh "bundle exec #{ruby_command} #{test_script_filename}"
        end
        @task_name = t.name
      end
    end
  end
end
