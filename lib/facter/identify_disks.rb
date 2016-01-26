#require 'pathname'
#
def parse_blockdev_dir()
  sysfs_block_directory = '/sys/block/'
  blockdevices = {}

  if File.exist?(sysfs_block_directory)
    Dir.entries(sysfs_block_directory).each do |device|
      if (device =~ /^md\d+/)
        (blockdevices["mdadm"] ||= []) << device
      end
    end
  end
  return blockdevices
end

Facter.add(:raid_arrays) do
  confine :kernel => 'Linux'
  setcode do
    parse_blockdev_dir
  end
end