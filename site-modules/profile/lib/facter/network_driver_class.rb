
Facter.add(:network_driver_class) do
  setcode do
    Dir.glob('/sys/class/net/*').any? do |iface|
      begin
        driver_path = File.realpath("#{iface}/device/driver")
        File.basename(driver_path) == 'e1000e'
      rescue
        false
      end
    end
  end
end
