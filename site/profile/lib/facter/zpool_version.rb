require 'facter'

Facter.add('zpool_version') do
  setcode do
    zpool_version = nil
    if Facter::Core::Execution.which('zpool')
      zpool_v = Facter::Core::Execution.exec('zpool upgrade -v')
      zpool_version = zpool_v.scan(%r{^\s+(\d+)\s+}m).flatten.last unless zpool_v.nil?
    end
    zpool_version
  end
end
