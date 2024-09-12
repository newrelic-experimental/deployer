require "./src/common/validators/validator"

module UserConfig
  module Validators
    module Azure
      class SshKeyValidator

        ERROR_DETAILS = "either 'sshPublicKeyPath' or 'sshPublicKeyValue' must exist"
        def initialize(error_message = nil)
          @error_message = error_message || "Invalid ssh key"
        end

        def execute(azure_configs)
          keyPath = getField(azure_configs, "sshPublicKeyPath")
          keyValue = getField(azure_configs, "sshPublicKeyValue")

          if keyPath.empty? && keyValue.empty?
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