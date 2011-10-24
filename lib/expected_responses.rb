require 'expectation_serializer'
ENV["RAILS_ASSET_ID"] = '' #http://rorl.collectivex.com/discussion/topic/show/26776 & http://maintainable.com/articles/rails_asset_cache pour les cons?quences que cela peut avoir
module ActionDispatch
  module Assertions
    # A small suite of assertions that test responses from \Rails applications.
    module ResponseAssertions
      include ExpectationSerializer
      def binary?
        @response.headers['Content-Transfer-Encoding'] == 'binary'
      end
      attr_accessor :batch, :output
      def save_response(type, message = nil, path = '')
        format = @request.parameters[:format] if @request and @request.parameters
        self.output||= 'expected_responses' # GetText.locale.to_s == "en" ? 'expected_views' : 'html'
        format ||= @response.headers['Content-Type'].split(';').first.split('/').first if @response.headers['Content-Type'] and @response.headers['Content-Type'].split('/').last == 'plain'
        format ||= @response.headers['Content-Disposition'].gsub('"','').split('.').last if @response.headers['Content-Disposition']
        format ||= @response.headers['type'].split(';').first.split('/').last if binary? and @response.headers['type']
        format ||= @response.headers['Content-Type'].split(';').first.split('/').last if @response.headers['Content-Type']
        format ||= 'html'
        binary = binary? ? "wb" : "w"
        if type == :success #and ((format == 'application/pdf' and @request.path_parameters['action'] == 'show') or (@request.path_parameters['controller'] == 'sites/registrations'))
          FileUtils.mkdir_p "#{expected_response_root}/#{output}/#{self.file_path}/" unless File.exists? "#{expected_response_root}/#{output}/#{self.file_path}/"
          unless batch
            file_name = "#{expected_response_root}/#{output}/#{file_path}/#{self.meth_name}.#{format}"
          else
            file_name = "#{expected_response_root}/#{output}/#{file_path}/#{self.meth_name}_#{@request.path_parameters['id']||@request.path_parameters['payment_id']||@request.path_parameters['congress_id']}.#{format}"
          end
          f = File.new(file_name, binary)
          if format == 'html' and defined? RailsTidy and RailsTidy.tidy_path
            RailsTidy.filter(@response)
          end
          if @response.body.is_a? Proc
            @response.body.call(@response, f)
          else
            f.write(@response.body)
          end
          f.close
        elsif type == :redirect or type == :missing
          file_name = "#{expected_response_root}/#{output}/#{file_path}/#{self.meth_name}.#{format}"
          File.delete(file_name) if File.exists? file_name
        end
      end
      def assert_response(type, message = nil)
        save_response(type, message)
        validate_request!

        if type.in?([:success, :missing, :redirect, :error]) && @response.send("#{type}?")
          assert_block("") { true } # to count the assertion
        elsif type.is_a?(Fixnum) && @response.response_code == type
          assert_block("") { true } # to count the assertion
        elsif type.is_a?(Symbol) && @response.response_code == Rack::Utils::SYMBOL_TO_STATUS_CODE[type]
          assert_block("") { true } # to count the assertion
        else
          flunk(build_message(message, "Expected response to be a <?>, but was <?>", type, @response.response_code))
        end
      end
    end
  end
end
