# frozen_string_literal: true

# Fact: kopia_orchestrator_pubkey
#
# Exposes the public half of the Kopia orchestrator's SSH keypair as
# { 'type' => 'ssh-ed25519', 'key' => 'AAAA...' } so that
# profile::app::kopia::orchestrator can export it as an ssh_authorized_key.
#
# The fact is absent on every node without the keypair, and on the orchestrator
# until Puppet has generated it (so the key is exported from the second run).
#
# The path must match "${config_dir}/id_ed25519.pub" in the orchestrator class.
Facter.add(:kopia_orchestrator_pubkey) do
  confine kernel: 'Linux'

  setcode do
    path = '/etc/kopia-orchestrator/id_ed25519.pub'
    if File.readable?(path)
      type, key, = File.read(path).split
      { 'type' => type, 'key' => key } if type && key
    end
  end
end
