Facter.add(:lxd_client_cert) do
  confine kernel: 'Linux'

  setcode do
    cert_path = "/root/snap/lxd/common/config/client.crt"
    if File.readable?(cert_path)
      File.read(cert_path)
    else
      nil
    end
  end
end
