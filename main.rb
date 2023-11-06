#!/usr/bin/env ruby

require_relative 'src/orchestrator'
require_relative 'src/context'
require "./src/common/validation_error"
require "./src/common/logger/logger_factory"

begin
  context = Context.new()
  orchestrator = Orchestrator.new(context)
  orchestrator.execute()
rescue Exception => e
  unless e.message.downcase() == "exit"
    Common::Logger::LoggerFactory.get_logger.error(e)
    Common::Logger::LoggerFactory.get_logger.error(e.backtrace)
    puts "\n{ \"deploy_config_url\":\"#{context.get_command_line_provider.get_deploy_config_filepath}\", \"deployment_action\": \"error\" } \n\n"
  end
  exit(1)
end
exit(0)
