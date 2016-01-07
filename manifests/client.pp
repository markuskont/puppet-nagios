# == Class: nagios::client
#
# Class for setting up Nagios Server
# Exported client resources are automatically loaded from puppetdb
# === Parameters
#
# === Variables
#
# === Examples
#
#  class { 'nagios::client': }
#
class nagios::client (
  $confdir        =   $nagios::params::confdir,
  $plugin_package =   $nagios::params::plugin_package,
  $user           =   $nagios::params::user,
  $ssh            =   undef,
  $ssh_public_key =   undef,
  $check_load     =   true
  ) inherits nagios::params {

  $target = "${confdir}/${fqdn}.cfg"
  package { $plugin_package: 
    ensure        =>  present,
  }
  @@nagios_host { $fqdn:
    ensure        =>  present,
    alias         =>  $::hostname,
    address       =>  $::fqdn,
    use           =>  "generic-host",
    target        =>  $target,
    owner         =>  $user,
    mode          =>  '0640'
  }
  if $ssh {
    class { '::nagios::client::ssh':
      ssh_public_key  =>  $ssh_public_key
    }
  }
}