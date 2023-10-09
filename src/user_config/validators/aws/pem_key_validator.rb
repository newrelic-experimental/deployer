require "./src/common/validators/file_exist"
require "./src/common/validators/validator"

module UserConfig
  module Validators
    module Aws
      class PemKeyValidator

        ERROR_DETAILS = "either 'secretKeyPath' or 'secretKeyName' and 'secretKeyData' must exist"
        def initialize(error_message = nil)
          @error_message = error_message || "Invalid Pem key"
        end

        def execute(aws_configs)
          keyName = getField(aws_configs, "secretKeyName")
          keyData = getField(aws_configs, "secretKeyData")
          keyPath = getField(aws_configs, "secretKeyPath")

          if (keyPath.empty? && (keyName.empty? || keyData.empty?))
            return "#{@error_message}: #{ERROR_DETAILS}"
          end

          return nil
        end

        def getField(configs, field_name)
          (configs || []).each do |config|
            unless (config[field_name.to_sym] || "").empty?
              return config[field_name.to_sym]
            end
            unless (config[field_name] || "").empty?
              return config[field_name]
            end
            return ""
          end
        end
      end
    end
  end
end