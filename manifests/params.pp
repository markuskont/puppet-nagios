# == Class: nagios::params
#
# This defines default configuration values for nagios.
# You don't want to use it directly.
#
# === Parameters
#
# === Variables
#
# === Examples
#
#  class { 'nagios::params': }
#
class nagios::params {
  $server_package     	=   'nagios3'
  $confdir        		=   "/etc/nagios3/conf.d"
  $user           		=   'nagios'

  $plugin_package     	=   'nagios-plugins-basic'
  $custom_plugins_dir   =   '/opt/nagios_plugins'
  $homedir 				= 	'/var/lib/nagios'

  $load_check_enabled	= 	true
  $raid_check_enabled	= 	true

  $megaraid_package 	= 	'megacli'
  $megaraid_binary 		= 	'/usr/sbin/megacli'

  $sudoers_file			= 	'/etc/sudoers.d/nagios'
}