# frozen_string_literal: true

class S3
  def initialize(docker)
    @docker = docker
  end

  def create_bucket(opts)
    @docker.execute_command('aws ' \
                            "--endpoint-url #{opts[:endpoint_url]} " \
                            's3 ' \
                            'mb ' \
                            "#{opts[:bucket_path]} " \
                            "--region \"#{opts[:region]}\"")
  end

  def create_object(opts)
    @docker.execute_command("printf #{Shellwords.escape(opts[:content])} | " \
                            'aws ' \
                            "--endpoint-url #{opts[:endpoint_url]} " \
                            's3 ' \
                            'cp ' \
                            '- ' \
                            "#{opts[:object_path]} " \
                            "--region \"#{opts[:region]}\" " \
                            '--sse AES256')
  end
end

class KMS
  def initialize(docker)
    @docker = docker
  end

  def create_key(opts)
    command = @docker.execute_command(
      "aws --endpoint-url #{opts[:endpoint_url]} "\
      "kms create-key --region #{opts[:region]}"
    )

    JSON.parse(command.stdout)
  end
end
