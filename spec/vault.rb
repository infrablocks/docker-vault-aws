# frozen_string_literal: true

class Vault
  def initialize(docker)
    @docker = docker
    @init_result = ''
  end

  def init
    @init_result = @docker.execute_command('vault operator init').stdout
  end

  def unseal_with_keyshares
    key1 = @init_result.match(/Unseal Key 1: (.*)\n/)[1]
    key2 = @init_result.match(/Unseal Key 2: (.*)\n/)[1]
    key3 = @init_result.match(/Unseal Key 3: (.*)\n/)[1]

    @docker.execute_command("vault operator unseal #{key1}")
    @docker.execute_command("vault operator unseal #{key2}")
    @docker.execute_command("vault operator unseal #{key3}")
  end

  def status
    @docker.execute_command('vault status').stdout
  end
end
