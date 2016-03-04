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
  $confdir          =   $nagios::params::confdir,
  $plugin_package   =   $nagios::params::plugin_package,
  $user             =   $nagios::params::user,
  $ssh              =   undef,
  $nagios_ssh_keys  =   {},
  $check_load       =   true
  ) inherits nagios::params {

  $target = "${confdir}/${environment}.cfg"
  package { $plugin_package: 
    ensure        =>  present,
  }
  @@nagios_host { $fqdn:
    ensure        =>  present,
    alias         =>  $::hostname,
    address       =>  $::ipaddress,
    use           =>  "generic-host",
    target        =>  $target,
    owner         =>  $user,
    mode          =>  '0640'
  }
  if $ssh {
    class { '::nagios::client::ssh':
      nagios_ssh_keys  =>  $nagios_ssh_keys
    }
  }
  if $email_server {
    notify {'email':}
    @@nagios_service { "check_rbl_${fqdn}":
      check_command       => "check_rbl",
      use                 => "generic-service",
      host_name           => $::fqdn,
      target              => "${confdir}/${fqdn}_services.cfg",
      notification_period => "24x7",
      service_description => 'RBL check',
      check_interval      => 30,
      tag                 => $::environment
    }
  }
}