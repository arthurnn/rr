require File.expand_path('../../spec_helper', __FILE__)

describe 'Integration with RSpec 2' do
  include IntegrationTests::RubyRSpec

  def configure_project_generator(project_generator)
    super
    project_generator.configure do |project|
      project.rspec_version = 2
    end
  end

  def self.including_the_adapter_manually_works
    specify "including the adapter manually works" do
      project = generate_project do |project|
        project.add_to_prelude <<-EOT
          RSpec.configure do |c|
            c.mock_with :rr
          end
        EOT
      end
      project.add_test_file do |file|
        file.add_working_test_case_with_adapter_tests do |test_case|
          test_case.add_to_body <<-EOT
            it 'loads the correct adapters' do
              assert_adapters_loaded #{adapters_that_should_be_loaded.inspect}
            end
          EOT
        end
      end
      result = project.run_tests
      result.should be_success
      result.should_not have_errors_or_failures
    end
  end

  def self.rr_hooks_into_the_test_framework_automatically
    specify "RR hooks into the test framework automatically" do
      project = generate_project
      project.add_test_file do |file|
        file.add_working_test_case
      end
      result = project.run_tests
      result.should be_success
      result.should_not have_errors_or_failures
    end
  end

  context 'when Bundler is autorequiring RR' do
    def configure_project_generator(project_generator)
      super
      project_generator.configure do |project|
        project.autorequire_gems = true
      end
    end

    def adapters_that_should_be_loaded
      [:RSpec2]
    end

    including_the_adapter_manually_works
  end

  context 'when RR is being required manually' do
    def configure_project_generator(project_generator)
      super
      project_generator.configure do |project|
        project.autorequire_gems = false
      end
    end

    def adapters_that_should_be_loaded
      [:RSpec2]
    end

    rr_hooks_into_the_test_framework_automatically
    including_the_adapter_manually_works

    specify "when RR raises an error it raises a failure not an exception" do
      project = generate_project
      project.add_test_file do |file|
        file.add_test_case do |test_case|
          test_case.add_test <<-EOT
            object = Object.new
            mock(object).foo
          EOT
        end
      end
      result = project.run_tests
      result.should fail_with_output(/1 failure/)
    end

    specify "it is still possible to use a custom RSpec-2 adapter" do
      project = generate_project do |project|
        project.add_to_prelude <<-EOT
          module RR
            module Adapters
              module RSpec2
                include RRMethods

                def setup_mocks_for_rspec
                  RR.reset
                end

                def verify_mocks_for_rspec
                  RR.verify
                end

                def teardown_mocks_for_rspec
                  RR.reset
                end

                def have_received(method = nil)
                  RR::Adapters::Rspec::InvocationMatcher.new(method)
                end
              end
            end
          end

          RSpec.configure do |c|
            c.mock_with RR::Adapters::RSpec2
          end
        EOT
      end
      project.add_test_file do |file|
        file.add_test_case_with_adapter_tests
      end
      result = project.run_tests
      result.should be_success
      result.should_not have_errors_or_failures
    end
  end
end
