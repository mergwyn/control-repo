Facter.add(:network_driver_class) do
  setcode do
    drivers = Dir.glob('/sys/class/net/*').map do |iface|
      driver_path = "#{iface}/device/driver"
      next unless File.exist?(driver_path)

      begin
        File.basename(File.realpath(driver_path))
      rescue
        nil
      end
    end.compact.uniq

    if drivers.include?('e1000e')
      'e1000e'
    else
      'generic'
    end
  end
end
