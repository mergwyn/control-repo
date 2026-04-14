Facter.add(:network_driver_class) do
  setcode do
    if Dir.glob('/sys/class/net/*').any? { |i|
      File.basename(File.realpath("#{i}/device/driver") rescue '') == 'e1000e'
    }
      'e1000e'
    else
      'generic'
    end
  end
end
