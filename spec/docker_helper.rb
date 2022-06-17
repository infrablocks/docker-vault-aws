class DockerHelper
  def initialize(command)
    @command = command
  end

  def execute_command(command_string)
    command = @command.(command_string)
    exit_status = command.exit_status
    unless exit_status == 0
      raise "\"#{command_string}\" failed with exit code: #{exit_status}, " \
            " #{command.stderr}"
    end

    command
  end
end
