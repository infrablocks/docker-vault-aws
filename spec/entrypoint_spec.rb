# frozen_string_literal: true

require 'spec_helper'
require 'aws'

describe 'entrypoint' do
  metadata_service_url = 'http://metadata:1338'
  localstack_endpoint_url = 'http://localhost:4566'
  container_aws_endpoint_url = 'http://localstack:4566'
  aws_region = 'us-east-1'
  s3_bucket_path = 's3://bucket'
  s3_env_file_object_path = 's3://bucket/env-file.env'

  environment = {
    'AWS_METADATA_SERVICE_URL' => metadata_service_url,
    'AWS_ACCESS_KEY_ID' => '...',
    'AWS_SECRET_ACCESS_KEY' => '...',
    'AWS_DEFAULT_REGION' => aws_region,
    'AWS_S3_ENDPOINT_URL' => container_aws_endpoint_url,
    'AWS_S3_BUCKET_REGION' => aws_region,
    'AWS_S3_ENV_FILE_OBJECT_PATH' => s3_env_file_object_path,
    'AWS_KMS_ENDPOINT' => container_aws_endpoint_url,
    'SKIP_SETCAP' => true,
    'VAULT_ADDR' => 'http://127.0.0.1:8200',
    'TLS_DISABLE' => 1
  }
  image = 'vault-aws:latest'
  extra = {
    'Entrypoint' => '/bin/sh',
    'HostConfig' => {
      'Binds' => ['/var/run/docker.sock:/tmp/docker.sock'],
      'NetworkMode' => 'docker_vault_aws_test_default'
    }
  }

  before(:all) do
    set :backend, :docker
    set :docker_image, image
    set :docker_container_create_options, extra
    set :env, environment
  end

  describe 'by default' do
    before(:all) do
      kms_key = KMS::create_key(
        endpoint_url: localstack_endpoint_url,
        region: aws_region
      )

      S3::create_bucket(
        endpoint_url: localstack_endpoint_url,
        region: aws_region,
        bucket_path: s3_bucket_path,
      )
      create_env_file(
        endpoint_url: localstack_endpoint_url,
        region: aws_region,
        bucket_path: s3_bucket_path,
        object_path: s3_env_file_object_path,
        env: {
          'VAULT_SEAL_TYPE' => 'awskms',
          'VAULT_AWSKMS_SEAL_KEY_ID' => kms_key['KeyMetadata']['KeyId']
        }
      )

      execute_docker_entrypoint(
        started_indicator: 'Vault server started!'
      )
    end

    after(:all, &:reset_docker_backend)

    it 'runs vault' do
      expect(process('.*vault server.*')).to(be_running)
    end

    it 'gets config from /vault/config' do
      expect(process('.*vault server.*').args)
        .to(match(%r{-config=/vault/config}))
    end

    describe 'when initialized' do
      init_result = ''

      before(:all) do
        init_result = execute_command('vault operator init').stdout
      end

      it 'is initialized' do
        expect(init_result).to(contain('Success! Vault is initialized'))
      end

      it 'auto unseals using kms' do
        proof_of_auto_unseal = 'Recovery Key'

        expect(init_result).to(contain(proof_of_auto_unseal))
      end
    end
  end

  def reset_docker_backend
    Specinfra::Backend::Docker.instance.send :cleanup_container
    Specinfra::Backend::Docker.clear
  end

  def create_env_file(opts)
    S3::create_object(
      opts
        .merge(
          content: (opts[:env] || {})
                     .to_a
                     .collect { |item| " #{item[0]}=\"#{item[1]}\"" }
                     .join("\n")
        )
    )
  end

  def execute_command(command_string)
    command = command(command_string)
    exit_status = command.exit_status
    unless exit_status == 0
      raise "\"#{command_string}\" failed with exit code: #{exit_status}, " \
            " #{command.stderr}"
    end

    command
  end

  def wait_for_contents(file, content)
    Octopoller.poll(timeout: 30) do
      docker_entrypoint_log = command("cat #{file}").stdout
      docker_entrypoint_log =~ /#{content}/ ? docker_entrypoint_log : :re_poll
    end
  rescue Octopoller::TimeoutError => e
    puts command("cat #{file}").stdout
    raise e
  end

  def execute_docker_entrypoint(opts)
    args = (opts[:arguments] || []).join(' ')
    logfile_path = '/tmp/docker-entrypoint.log'
    start_command = "docker-entrypoint.sh #{args} > #{logfile_path} 2>&1 &"
    started_indicator = opts[:started_indicator]

    execute_command(start_command)
    wait_for_contents(logfile_path, started_indicator)
  end
end
