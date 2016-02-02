#require 'pathname'
require 'open3'

def parse_udev_driver(device)
  driver = ''
  cmd = "udevadm info -a -n #{device}"
  Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
    while line = stdout.gets
      if /DRIVERS=="(megaraid_sas)"/.match(line)
        return $1
      end
    end
  end
end

def parse_blockdev_dir()
  sysfs_block_directory = '/sys/block/'
  blockdevices = {}

  if File.exist?(sysfs_block_directory)
    Dir.entries(sysfs_block_directory).each do |device|
      if (device =~ /^md\d+/)
        driver = 'mdadm'
      else
        driver = parse_udev_driver(device)
      end
      if driver
        (blockdevices[driver] ||= []) << device
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