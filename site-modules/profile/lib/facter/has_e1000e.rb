Facter.add(:has_e1000e) do
  setcode do
    Dir.glob('/sys/class/net/*').any? do |iface|
      File.basename(File.realpath("#{iface}/device/driver") rescue '') == 'e1000e'
    end
  end
end
