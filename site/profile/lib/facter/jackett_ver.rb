require 'facter'

# Default for non-Linux nodes
#
Facter.add(:jackett_ver) do
    setcode do
        nil
    end
end

# Linux
#
Facter.add(:jackett_ver) do
    confine :kernel  => :linux
    setcode do
        Facter::Util::Resolution.exec("wget -q https://github.com/Jackett/Jackett/releases/latest -O - | grep -E \/tag\/ | awk -F '[><]' '{print $3}'")
    end
end

