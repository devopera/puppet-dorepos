# install a devopera standard repo-based application
define dorepos::installapp (

  $appname = $title,
  $repo = {
    provider => 'git',
    path => '/var/www/git/github.com',
    require => File['/var/www/git/github.com/'], 
  },
  $byrepo_filewriteable = {},
  
  # undefined variables, set as {} to exclude
  # $byrepo_hosts
  # $byrepo_vhosts

  # always refresh repo, host and vhost, even if notifier present
  $refresh = true,
  $notifier_dir = '/etc/puppet/tmp',

  # refresh apache after installing app
  $refresh_apache = true,

) {

  # checkout extra config from (read-only) appconfig-drupal
  dorepos::getrepo { "$appname" :
    provider => $repo['provider'],
    path => $repo['path'],
    source => $repo['source'],
  }

  # ensure files directories are web accessible
  $byrepo_filewriteable_defaults = {
    user => $user,
    mode => 6660,
    groupfacl => 'rwx',
    recurse => true,
    require => Dorepos::Getrepo["$appname"],
  }
  if ($byrepo_filewriteable != {}) {
    create_resources(docommon::stickydir, $byrepo_filewriteable, $byrepo_filewriteable_defaults)
  } 

  # dynamically seek out hosts and vhosts
  if $byrepo_hosts == undef {
    $byrepo_resolved_hosts = {
      "hosts-$appname" => {
        source => "${repo['path']}/${name}/conf/hosts/*",
      },
    }
  } else {
    $byrepo_resolved_hosts = $byrepo_hosts
  }

  if $byrepo_vhosts == undef {
    $byrepo_resolved_vhosts = {
      "vhosts-$appname" => {
        source => "${repo['path']}/${name}/conf/vhosts/*",
        target => "/etc/${apache::params::apache_name}/conf.d/${name}-vhosts.conf",
      },
    }
  } else {
    $byrepo_resolved_vhosts = $byrepo_vhosts
  }

  # setup hosts from repos if not empty {}
  $byrepo_hosts_default = {
    target => '/etc/hosts',
    require => Dorepos::Getrepo["$appname"],
    before => File["puppet-installapp-$appname"],
  }
  if ($byrepo_resolved_hosts != {}) {
    create_resources(docommon::filesadd, $byrepo_resolved_hosts, $byrepo_hosts_default)
  }
  
  # setup vhosts from repos
  $byrepo_vhosts_default = {
    purge => true,
    require => Dorepos::Getrepo["$appname"],
    before => File["puppet-installapp-$appname"],
  }
  if ($byrepo_resolved_vhosts != {}) {
    create_resources(docommon::filesadd, $byrepo_resolved_vhosts, $byrepo_vhosts_default)
  }
  
  # consistent resource for later requirements
  file { "puppet-installapp-$appname" :
    path => "${notifier_dir}/puppet-installapp-$appname",
  }
  
  if ($refresh_apache) {
    # once all vhosts have been loaded into conf.d, restart apache
    exec { "vhosts-refresh-apache-$appname": 
      command => "/sbin/service ${apache::params::apache_name} graceful",
      require => File["puppet-installapp-$appname"],
    }
  }
}
