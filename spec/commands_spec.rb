# frozen_string_literal: true

require 'spec_helper'

describe 'commands' do
  image = 'vault-aws:latest'
  extra = {
    'Entrypoint' => '/bin/sh'
  }

  before(:all) do
    set :backend, :docker
    set :docker_image, image
    set :docker_container_create_options, extra
  end

  after(:all, &:reset_docker_backend)

  it 'includes the vault command' do
    expect(command('/bin/vault --version').stdout)
      .to match(/1.15/)
  end

  it 'includes the envsubst command' do
    expect(command('envsubst --version').stdout)
      .to(match(/0.21.1/))
  end

  def reset_docker_backend
    Specinfra::Backend::Docker.instance.send :cleanup_container
    Specinfra::Backend::Docker.clear
  end
end
