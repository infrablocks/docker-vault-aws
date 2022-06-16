def execute_cmd(*command_string)
  stdout, stderr, status = Open3.capture3(*command_string)
  unless status == 0
    raise "\"#{command_string}\" failed with exit code: #{status}, " \
            " #{stderr}"
  end
  stdout
end

module S3
  def S3.create_bucket(opts)
    execute_cmd('AWS_ACCESS_KEY_ID=... AWS_SECRET_ACCESS_KEY=... aws ' \
                    "--endpoint-url #{opts[:endpoint_url]} " \
                    's3 ' \
                    'mb ' \
                    "#{opts[:bucket_path]} " \
                    "--region \"#{opts[:region]}\"")
  end

  def S3.create_object(opts)
    execute_cmd("printf #{Shellwords.escape(opts[:content])} | " \
                    'AWS_ACCESS_KEY_ID=... AWS_SECRET_ACCESS_KEY=... aws ' \
                    "--endpoint-url #{opts[:endpoint_url]} " \
                    's3 ' \
                    'cp ' \
                    '- ' \
                    "#{opts[:object_path]} " \
                    "--region \"#{opts[:region]}\" " \
                    '--sse AES256')
  end
end

module KMS
  def KMS.create_key(opts)
    cmd = 'AWS_ACCESS_KEY_ID=... AWS_SECRET_ACCESS_KEY=... aws ' \
          "--endpoint-url #{opts[:endpoint_url]} kms create-key --region #{opts[:region]}"
    res = `#{cmd}`

    JSON.parse(res)
  end
end
