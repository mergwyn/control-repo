# modules/profile/lib/facter/lxd_client_cert.rb
Facter.add(:lxd_client_cert) do
  confine { File.exist?('/root/snap/lxd/common/config/client.crt') }

  setcode do
    File.read('/root/snap/lxd/common/config/client.crt')
  end
end
