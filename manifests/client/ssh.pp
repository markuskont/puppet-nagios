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
  $nagios_ssh_keys      =   {},
  $custom_plugin_dir    =   $nagios::params::custom_plugins_dir,
  $user                 =   $nagios::params::user,
  $confdir              =   $nagios::params::confdir,
  $check_load           =   $nagios::params::load_check_enabled,
  $homedir              =   $nagios::params::homedir
  ) inherits nagios::client {

  if ( $nagios_ssh_keys == undef ) {
    fail 'Public keys must be defined as hash when using SSH'
  }
  file { $homedir:
    ensure      => directory,
    mode        => '0750',
    owner       => $user,
  }
  user { "$user":
    ensure      => 'present',
    password    => '!',
    shell       => '/bin/bash',
    home        => $homedir,
    managehome  => true,
    require     => File[$homedir]
  }

  $key_defaults = {
    'ensure'    =>  present,
    'user'      =>  $user,
    'type'      =>  'rsa'
  }

  create_resources(ssh_authorized_key, $nagios_ssh_keys, $key_defaults)
  #ssh_authorized_key { "${user}_public_key":
  #  user        => $user,
  #  type        => 'rsa',
  #  key         => $ssh_public_key,
  #  require     => [ User[$user] ],
  #}
  # Services
  if $check_load == true {
    # warning for 1, 5 and 15 minute load respectively
    $wload1 = $::processors['count'] * 2
    $wload5 = $::processors['count']
    $wload15 = $::processors['count']
    # critical for 1, 5 and 15 minute load respectively
    $cload1 = $::processors['count'] * 4
    $cload5 = floor($::processors['count'] * 1.5)
    $cload15 = floor($::processors['count'] * 1.5)

    @@nagios_service { "check_ssh_load_${fqdn}":
      check_command       => "check_ssh_load!${wload1}.0,${wload5}.0,${wload15}.0!${cload1}.0,${cload5}.0,${cload15}.0",
      use                 => "generic-service",
      host_name           => $::fqdn,
      target              => "${confdir}/${fqdn}_services.cfg",
      notification_period => "24x7",
      service_description => 'Host Load Check via SSH'
    }  
  }
}