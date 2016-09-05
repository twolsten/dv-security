#
#
# Purpose: Configure system to meet defined security standards
# Author : Tom Wolstencroft
# Date: 9/1/16
# Limitations:


class datavail {

  # Set defaults for types

  File {
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  # Packages that should be removed
  package { [ 'mctrans', 'setroubleshoot' ]:
    ensure =>purged,
  }

  # Set file permissions.  Defaults are inheritted

  file { '/boot/grub/grub.conf':
    mode => '0600',
  }

  # Install and configure auditd
  package { 'audit':
    ensure => present,
  }

  service { 'auditd':
    ensure  => 'running',
    enabled => true,
  }

  file { '/etc/audit/auditd.conf':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '640',
    source => '/tmp/dv-security/files/auditd.conf',
    notify => Service['auditd'],
  }

  file { '/etc/audit/rules.d/audit.rules':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0640',
    source => '/tmp/dv-security/files/audit.rules',
    notify => Service['auditd'],
  }

  # Configure SELinux

  file { '/etc/selinux/config':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => '/tmp/dv-security/files/selinux',
  }

  file { '/etc/sysconfig/init':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => '/tmp/dv-security/files/init',
  }

  # Ensure Yum has gpgcheck globally enabled

  file_line { 'Enable gpgcheck':
    path  => '/etc/yum.conf',
    line  => 'gpgcheck=1',
    match => '^gpgcheck\=',
  }

  # Restrict core dumpts

  file_line { 'set core dump limits':
    path => '/etc/security/limits.conf',
    line => "*  hard  core  0",
  }

  sysctl { 'fs.suid_dumpable':
    ensure => present,
    value  => '0',
  }

  sysctl { 'kernel.exec-shield':
    ensure => present,
    value  => '1',
  }

  sysctl { 'kernel.randomize_va_space':
    ensure => present,
    value  => '2',
  }

  # Remove legacy services

  package { ['telnet-server', 'telnet', 'rsh-server', 'rsh', 'ypbind', 'ypserv', 'tftp', 'tftp-server', 'talk', 'talk-server']:
    ensure => purged,
  }

  # Disable legacy services

  service { ['chargen-dgram', 'chargen-stream', 'daytime-dgram', 'daytime-stream', 'ech-dgram', 'echo-stream', 'tcpmux-server']:
    ensure => 'stopped',
    enable => false,
  }

  # Set umask in /etc/sysconfit/init

  file_line { 'init umask':
    path => '/etc/sysconfig/init',
    line => "umask 027",
  }

  # Disable ip forwarding

  sysctl { 'net.ipv4_forward':
    ensure => present,
    value  => '0',
  }

  sysctl {"net.ipv4.conf.all.send_redirects":
    ensure => present,
    value  => '0',
  }

  sysctl {"net.ipv4.conf.all.accept_redirects":
    ensure => present,
    value  => '0',
  }

  sysctl {"net.ipv4.conf.all.secure_redirects":
    ensure => present,
    value  => '0',
  }

  sysctl {"net.ipv4.conf.default.log_martians":
    ensure => present,
    value  => '1',
  }

  sysctl {"net.ipv4.conf.all.rp_filter":
    ensure => present,
    value  => '0',
  } 

  sysctl { 'net.ipv4_icmp_echo_ignore_broadcasts':
    ensure => present,
    value  => '1',
  }

  sysctl { 'net.ipv4.icmp_ignore_bogus_error_responses':
    ensure => present,
    value  => '1',
  }

  sysctl { 'net.ipv4.tcp_syncookies':
    ensure => present,
    value  => '1',
  }

  # configure syslog

  package { 'rsyslog':
    ensure => present,
  }

  service { 'rsyslog':
    ensure  => 'running',
    enable  => true,
    require => Package['rsyslog'],
  }

  service { 'syslog':
    ensure => stopped,
    enable => false,
  }

  file { 'rsyslog':
    ensure => present,
    path   => '/etc/rsyslog.conf',
    owner  => 'root',
    group  => 'root',
    source => '/tmp/dv-security/rsyslog.conf',
    notify => Service['rsyslog'],
  }

  file { 'syslog':
    ensure => present,
    path   => '/etc/logrotate.d/syslog',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => '/tmp/dv-security/syslog',
  }

  # Configure cron services

  service { ['anacron', 'crond']:
    ensure => running,
    enable => true,
  }

  file { 'anacrontab':
    path   => '/etc/anacrontab',
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0600',
  }

  file { 'crontab':
    path   => '/etc/crontab',
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0600',
  }

  file { 'cron.daily':
    ensure => directory,
    path   => '/etc/cron.daily',
    owner  => 'root',
    group  => 'root',
    mode   => '0600',
  }

  # Verify file permissions

  file { 'passwd':
    path   => '/etc/passwd',
  }

  file { 'shadow':
    path => '/etc/shadow',
  }

  file { 'gshadow':
    path => '/etc/gshadow',
  }

  file { 'group':
    path => '/etc/group',
  }
  
  file { 'motd':
    path => '/etc/motd',
  }

  file { 'issue':
    path => '/etc/issue',
  }

  file { 'issue.net':
    path => '/etc/issue.net',
  }
}









