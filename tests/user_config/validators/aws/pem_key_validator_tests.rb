require "minitest/spec"
require "minitest/autorun"
require 'mocha/minitest'

require "./src/user_config/validators/aws/pem_key_validator"

describe "UserConfig::Validators::Aws::PemKeyValidator" do
  let(:aws_configs) { [] }
  let(:error_message_test) { "Error testing" }
  let(:validator) { UserConfig::Validators::Aws::PemKeyValidator.new(error_message_test) }

  it "should create validator" do
    validator.wont_be_nil
  end

  it "should execute pem_key_validator" do
    given_aws_credential("myPemKeyName", "SuperSecretPrivateKeyData", "/some/path/to/my.pem")
    validator.execute(aws_configs)
  end

  it "should error whenever one of name/data is empty, and path is empty " do
    given_aws_credential("myPemKeyName", nil, nil)
    errorMessage = validator.execute(aws_configs)
    errorMessage.wont_be_nil()
    errorMessage.must_include(error_message_test)
    errorMessage.must_include(UserConfig::Validators::Aws::PemKeyValidator::ERROR_DETAILS)

    given_aws_credential(nil, "pemData", nil)
    errorMessage = validator.execute(aws_configs)
    errorMessage.wont_be_nil()
    errorMessage.must_include(error_message_test)
    errorMessage.must_include(UserConfig::Validators::Aws::PemKeyValidator::ERROR_DETAILS)
  end

  it "should error when pem name, pem data and path are all empty" do
    given_aws_credential(nil, "pemData", nil)
    errorMessage = validator.execute(aws_configs)
    errorMessage.wont_be_nil()
    errorMessage.must_include(error_message_test)
    errorMessage.must_include(UserConfig::Validators::Aws::PemKeyValidator::ERROR_DETAILS)
  end

  it "should pass when pem name and pem data are present" do
    given_aws_credential("pemName", "pemData", nil)
    errorMessage = validator.execute(aws_configs)
    errorMessage.must_be_nil()
  end

  it "should pass when pem path is present" do
    given_aws_credential(nil, nil, "/some/pem/path")
    errorMessage = validator.execute(aws_configs)
    errorMessage.must_be_nil()
  end

  def given_aws_credential(pem_key_name = nil, pem_key_data = nil, pem_key_path = nil)
    aws_config = {}
    unless pem_key_name.nil?
      aws_config["secretKeyName"] = pem_key_name
    end
    unless pem_key_data.nil?
      aws_config["secretKeyData"] = pem_key_data
    end
    unless pem_key_path.nil?
      aws_config["secretKeyPath"] = pem_key_path
    end
    aws_configs.push(aws_config)
  end

end # frozen_string_literal: true

