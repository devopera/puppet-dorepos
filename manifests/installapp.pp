# install a devopera standard repo-based application
define dorepos::installapp (

  $appname = $title,
  $user = 'web',
  $group = 'www-data',
  $byrepo_filewriteable = {},

  # default repo settings  
  $repo_source = undef,
  $repo_provider = 'git',
  $repo_path = '/var/www/git/github.com',
  $repo_require = File['/var/www/git/github.com/'],
  $repo_provider_options = '',
  $repo_branch = 'master',
  $repo_submodule_branch = 'master',
  $repo_force_submodule_branch = false,
  $repo_force_perms_onsh = false,

  # undefined variables, set as undef to use defaults
  $byrepo_hosts = undef,
  $byrepo_vhosts = undef,
  $byrepo_crontabs = undef,
  $byrepo_databases = undef,

  # always refresh repo, host and vhost, even if notifier present
  $refresh = true,
  $notifier_dir = '/etc/puppet/tmp',

  # refresh apache after installing app
  $refresh_apache = true,

  # create symlink and if so, where
  $symlinkdir = false,

  # flags to control installation
  $install_crontabs = false,
  $install_databases = false,
  $install_filesets = false,
  
) {

  if ($repo_source != undef) {
    # checkout repo
    dorepos::getrepo { "$appname" :
      user => $user,
      group => $group,
      provider => $repo_provider,
      provider_options => $repo_provider_options,
      path => $repo_path,
      source => $repo_source,
      branch => $repo_branch,
      submodule_branch => $repo_submodule_branch,
      force_submodule_branch => $repo_force_submodule_branch,
      force_perms_onsh => $repo_force_perms_onsh,
      symlinkdir => $symlinkdir,
      require => $repo_require,
    }
  }

  # ensure files directories are web accessible
  $byrepo_filewriteable_defaults = {
    user => $user,
    group => $group,
    mode => 2660,
    dirmode => 2770,
    groupfacl => 'rwx',
    recurse => true,
    context => 'httpd_sys_content_t',
    require => Dorepos::Getrepo["$appname"],
  }
  if ($byrepo_filewriteable != {}) {
    create_resources(docommon::stickydir, $byrepo_filewriteable, $byrepo_filewriteable_defaults)
  } 

  # dynamically seek out hosts and vhosts
  if ($byrepo_hosts == undef) {
    $byrepo_resolved_hosts = {
      "hosts-$appname" => {
        source => "${repo_path}/${name}/conf/hosts/*",
      },
    }
  } else {
    $byrepo_resolved_hosts = $byrepo_hosts
  }

  if ($byrepo_vhosts == undef) {
    $byrepo_resolved_vhosts = {
      "vhosts-$appname" => {
        source => "${repo_path}/${name}/conf/vhosts/*",
        target => "${apache::params::vhost_dir}/${name}-vhosts.conf",
        postcommand => $osfamily ? {
          debian => "a2ensite ${name}-vhosts.conf",
          default => undef,
        }
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
      path => '/bin:/usr/bin:/sbin:/usr/sbin',
      command => "service ${apache::params::apache_name} graceful",
      tag => ['service-sensitive'],
      require => File["puppet-installapp-$appname"],
    }
  }

  # if we're supposed to be installing crontabs in this run
  if ($install_crontabs) {
    notify { "installing crontabs for ${appname}" : }
    
    # aggregate multiple files within single app
    if ($byrepo_crontabs == undef) {
      $byrepo_resolved_crontabs = {
        "crontab-${appname}" => {
          directory => "${repo_path}/${name}/conf/cron",
        },
      }
    } else {
      $byrepo_resolved_crontabs = $byrepo_crontabs
    }

    $byrepo_crontabs_defaults = {
      user => $user,
      purge => false,
      require => File["puppet-installapp-$appname"],
    }

    # concat all files in this /cron/ directory into a single file
    create_resources(docommon::findcrontab, $byrepo_resolved_crontabs, $byrepo_crontabs_defaults)
  }

  # install databases using repo (sensitive) scripts
  if ($install_databases) {
    notify { "installing databases for ${appname}" : }

    # identify top-level apply script
    if ($byrepo_databases == undef) {
      $byrepo_resolved_databases = {
        "all-databases-in-one-${appname}" => {
          directory => "${repo_path}/${name}/conf/backup/db/",
          wild => 'installapp_apply_all.sh',
        },
      }
    } else {
      $byrepo_resolved_databases = $byrepo_databases
    }

    $byrepo_databases_defaults = {
      # DB install scripts need to be run as root
      user => 'root',
      # need to set root user's home for access to .my.cnf
      precommand => "export HOME='/root'",
      # this can be removed to check DB everytime (in installapp_apply scripts)
      # create a notifier to only run once
      target => "installapp-databases-all-in-one-${appname}",
      require => File["puppet-installapp-${appname}"],
      before => Exec["puppet-installapp-${appname}-correctperms"],
    }
    
    # execute install DB scripts once only, even though they're sensitive to existing DBs
    create_resources(docommon::findrunonce, $byrepo_resolved_databases, $byrepo_databases_defaults)

    # installapp_apply_all.sh -> calls installapp_apply.sh -> calls apply_snapshot_to_db.sh (as root) so change perms
    exec { "puppet-installapp-${appname}-correctperms" :
      path => '/bin:/usr/bin:/sbin:/usr/sbin',
      command => "find ${repo_path}/${name} -name 'outgoing_database.sql' -exec chown ${user}:${group} {} \;",
      user => 'root',
    }
  }

}
