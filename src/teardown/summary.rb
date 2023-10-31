module Teardown
  class Summary

    def execute(deployment_name, deploy_config_url)
      summary = "Teardown successful!\n\n"

      deployment_name = get_deployment_name(deployment_name)
      deploy_config_url = get_deploy_config_url(deploy_config_url)

      summary += "    #{deployment_name}" unless deployment_name.empty?
      summary += "    #{deploy_config_url}" unless deploy_config_url.empty?

      Common::Logger::LoggerFactory.get_logger.info(summary)
    end

    def get_deploy_config_url(deploy_config_url)
      output = ""
      output += "deploy config url: #{deploy_config_url}\n" unless deploy_config_url.empty?
      return output
    end

    def get_deployment_name(deployment_name)
      output = ""
      output += "deployment name: #{deployment_name}\n" unless deployment_name.empty?
      return output
    end

  end
end