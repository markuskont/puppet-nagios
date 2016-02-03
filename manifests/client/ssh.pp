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
  $check_raid           =   $nagios::params::raid_check_enabled,
  $homedir              =   $nagios::params::homedir,
  $megaraid_package     =   $nagios::params::megaraid_package,
  $megaraid_binary      =   $nagios::params::megaraid_binary,
  $sudoers_file         =   $nagios::params::sudoers_file
  ) inherits nagios::client {

  if ( $nagios_ssh_keys == undef ) {
    fail 'Public keys must be defined as hash when using SSH'
  }
  user { "$user":
    ensure      => 'present',
    password    => '!',
    shell       => '/bin/bash',
    home        => $homedir,
    managehome  => true
  }
  file { $homedir:
    ensure      => directory,
    mode        => '0750',
    owner       => $user,
    require     => User[$user]
  }
  file { $custom_plugins_dir:
      ensure => "directory",
      mode => '0755',
      owner => $user,
  }
  $key_defaults = {
    'ensure'    =>  present,
    'user'      =>  $user,
    'type'      =>  'rsa'
  }

  create_resources(ssh_authorized_key, $nagios_ssh_keys, $key_defaults)
  # Services
  if $check_load == true {
    # warning for 1, 5 and 15 minute load respectively
    $wload1 = $::processors['count'] * 2
    $wload5 = $::processors['count']
    $wload15 = $::processors['count'] * 0.5
    # critical for 1, 5 and 15 minute load respectively
    $cload1 = $::processors['count'] * 4
    $cload5 = $::processors['count'] * 1.5
    $cload15 = $::processors['count']

    @@nagios_service { "check_ssh_load_${fqdn}":
      check_command       => "check_ssh_load!${wload1},${wload5},${wload15}!${cload1},${cload5},${cload15}",
      use                 => "generic-service",
      host_name           => $::fqdn,
      target              => "${confdir}/${fqdn}_services.cfg",
      notification_period => "24x7",
      service_description => 'Host Load Check via SSH',
      check_interval      => 1
    } 
  }
  if $check_raid == true and $::is_virtual == false and $blockdev_drivers {
    $mdadm_arrays = $blockdev_drivers['mdadm']
    if $mdadm_arrays {
      file { "${custom_plugins_dir}/check_md_raid":
          ensure => present,
          mode => '0750',
          owner => $user,
          group => root,
          source => "puppet:///modules/nagios/check_md_raid.py",
      }
      $mdadm_arrays.each |String $array| {
        @@nagios_service { "check_ssh_md_raid_${fqdn}_${array}":
          check_command       => "check_ssh_md_raid!${array}",
          use                 => "generic-service",
          host_name           => $::fqdn,
          target              => "${confdir}/${fqdn}_services.cfg",
          notification_period => "24x7",
          service_description => 'Linux Software RAID Check via SSH',
          check_interval      => 30
        }
      }
    }
    $megaraid_sas_arrays = $blockdev_drivers['megaraid_sas']
    if $megaraid_sas_arrays {
      file { $sudoers_file:
        ensure  => present,
        mode    => '0440',
        owner   => root,
        group   => root
      } ->
      file_line { 'allow-nagios-list-megacli-enclosure':
        path => "${sudoers_file}",
        line => "${user} ALL=(ALL) NOPASSWD: ${megaraid_binary} -EncInfo -AAll",
      }
      file_line { 'allow-nagios-list-megacli-logical-info':
        path    => "${sudoers_file}",
        line    => "${user} ALL=(ALL) NOPASSWD: ${megaraid_binary} -LDInfo -LAll -A*",
      }
      file_line { 'allow-nagios-list-megacli-physical-info':
        path => "${sudoers_file}",
        line => "${user} ALL=(ALL) NOPASSWD: ${megaraid_binary} -PDInfo -LAll -A*",
      }
      apt::source { 'hwraid':
        location    => 'http://hwraid.le-vert.net/debian',
        release     => "wheezy",
        repos       => "main",
        key         => '23B3D3B4',
        key_source  => 'http://hwraid.le-vert.net/debian/hwraid.le-vert.net.gpg.key',
      } ->
      package { "$megaraid_package":
        ensure => present
      }
      #$megaraid_sas_arrays.each |String $array| {
      #  notify{"testing, found ${array}":}
      #}
    }
  }
}