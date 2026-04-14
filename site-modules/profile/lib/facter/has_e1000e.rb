Facter.add(:has_e1000e) do
  setcode do
    Dir.glob('/sys/class/net/*').any? do |iface|
      driver_file = "#{iface}/device/driver"
      next false unless File.exist?(driver_file)

      begin
        File.basename(File.realpath(driver_file)) == 'e1000e'
      rescue
        false
      end
    end
  end
end
