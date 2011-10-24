require 'shoulda/action_mailer/assertions'
module Shoulda # :nodoc:
  module ActionMailer # :nodoc:
    module Assertions
      # Asserts that an email was delivered.  Can take a block that can further
      # narrow down the types of emails you're expecting.
      #
      #  assert_sent_email
      #
      # Passes if ActionMailer::Base.deliveries has an email
      #
      #  assert_sent_email do |email|
      #    email.subject =~ /hi there/ && email.to.include?('none@none.com')
      #  end
      #
      # Passes if there is an email with subject containing 'hi there' and
      # 'none@none.com' as one of the recipients.
      #
      def assert_sent_email
        emails = ::ActionMailer::Base.deliveries
        assert !emails.empty?, "No emails were sent"
        if block_given?
          matching_emails = emails.select {|email| yield email }
          assert !matching_emails.empty?, "None of the emails matched."
        end
        save_mail
      end
      include ExpectationSerializer
      def binary?
        false
      end
      def save_mail path = '', bat = '_'
        self.output ||= 'expected_responses'
        format = 'eml'
        binary = binary? ? "wb" : "w"
        FileUtils.mkdir_p "#{expected_response_root}/#{output}/#{self.file_path}/" unless File.exists? "#{expected_response_root}/#{output}/#{self.file_path}/"
        unless batch
          f = File.new("#{expected_response_root}/#{output}/#{file_path}/#{meth_name}#{path}.#{format}", binary)
        else
          f = File.new("#{expected_response_root}/#{output}/#{file_path}/#{meth_name}_#{@request.path_parameters['id']||@request.path_parameters['payment_id']||@request.path_parameters['congress_id']}#{path}.#{format}", binary)
        end
        f.write(::ActionMailer::Base.deliveries.last.to_s)
        f.close
      end
    end
  end
end