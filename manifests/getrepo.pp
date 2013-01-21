# clone/checkout a repo using bash and our loaded ssh-agent
define dorepos::getrepo (

  # class arguments
  # ---------------
  # setup defaults

  $provider,
  $path,
  $source,
  $user = 'web',
  $branch = 'master'

  # end of class arguments
  # ----------------------
  # begin class

) {
  # write clone command
  case $provider {
    git: {
      $command_clone = "git clone -b ${branch}"
      $command_update = 'git pull'
      $creates_dep = '.git'
    }
    svn: {
      $command_clone = 'svn checkout --quiet'
      $command_update = 'svn update --quiet .'
      $creates_dep = '.svn'
    }
  }

  # clone/checkout the repo if it doesn't exist already
  exec { "clone-${title}":
    path => '/usr/bin:/bin',
    provider => 'shell',
    command => "bash -c 'source /home/${user}/.ssh/environment; ${command_clone} ${source} ${path}/${title}'",
    cwd => "/home/${user}",
    user => $user,
    timeout => 0,
    logoutput => true,
    creates => "${path}/${title}/${creates_dep}",
    require => Class['dopki'],
  }

  # pull/update repo, incase it did exist
  exec { "update-${title}":
    path => '/usr/bin:/bin',
    provider => 'shell',
    command => "bash -c 'source /home/${user}/.ssh/environment; cd ${path}/${title}; ${command_update}'",
    cwd => "/home/${user}",
    user => $user,
    timeout => 0,
    logoutput => true,
    require => Exec["clone-${title}"],
  }

  # set protected permissions on script files
  exec { "set-perms-onsh-${title}" :
    path => '/usr/bin:/bin',
    command => "find ${path}/${title} -name '*.sh' -exec chmod 700 {} \;",
    require => Exec["update-${title}"],
  }
}
