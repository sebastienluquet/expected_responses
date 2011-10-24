module ExpectationSerializer
  attr_accessor :batch, :output
  def file_path
    if respond_to? 'delegate'
      delegate.class.to_s.split('::').join('/')
    else
      self.class.to_s.split('::').join('/')
    end
  end
  def expected_response_root
    "#{Rails.root}/tmp"
  end
  def meth_name
    if respond_to? 'delegate'
      delegate.method_name
    else
      method_name
    end
  end
end