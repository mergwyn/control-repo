Facter.add(:lxd_client_cert) do
  confine kernel: 'Linux'

  require 'base64'

  cert_path = '/root/snap/lxd/common/config/client.crt'

  if File.readable?(cert_path)
    Facter.add(:lxd_client_cert_b64) do
      setcode { Base64.strict_encode64(File.read(cert_path)) }
    end
  end
end
