# == Class: nagios::client::ssh
#
# Class for setting up Nagios Server
# Exported client resources are automatically loaded from puppetdb
# === Parameters
#
# === Variables
#
# === Examples
#
#  class { 'nagios::client::ssh': }
#
class nagios::client::ssh (
  $ssh_public_key       =   undef,
  $custom_plugin_dir    =   $nagios::params::custom_plugins_dir,
  $user                 =   $nagios::params::user,
  $confdir              =   $nagios::params::confdir,
  $check_load           =   true
  ) inherits nagios::client {

  if ( $ssh_public_key == undef ) {
    fail 'Public key must be defined when using SSH for remote access'
  }
  user { "$user":
    ensure      => 'present',
    password    => '!',
    shell       => '/bin/bash',
  }
  ssh_authorized_key { "${user}_public_key":
    user        => $user,
    type        => 'rsa',
    key         => $ssh_public_key,
    require     => [ User[$user] ],
  }
  # Services
  if check_load == true {
    @@nagios_service { "check_ssh_load_${fqdn}":
      check_command       => "check_ssh_load!5.0,4.0,3.0!10.0,6.0,4.0",
      use                 => "generic-service",
      host_name           => $::fqdn,
      target              => "${confdir}/${fqdn}.cfg",
      notification_period => "24x7",
      service_description => 'Host Load Check via SSH'
    }  
  }
}