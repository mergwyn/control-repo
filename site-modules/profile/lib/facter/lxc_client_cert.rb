Facter.add(:lxd_client_cert_b64) do
  confine kernel: 'Linux'

  require 'base64'

  cert_path = '/root/snap/lxd/common/config/client.crt'

  setcode do
    if File.readable?(cert_path)
      Base64.strict_encode64(File.binread(cert_path))
    else
      nil
    end
  end
end
