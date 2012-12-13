class dorepos (

  # class arguments
  # ---------------
  # setup defaults

  $user = 'web',
  $user_git_name = 'gituser',
  $user_git_email = 'gituser@example.com',
  $repos = {},
  $repos_default = {
    user => $user,
  },

  # end of class arguments
  # ----------------------
  # begin class

) {

  # configure git
  exec { 'git-config' :
    path => '/usr/bin:/bin',
    command => "export HOME=/home/${user}/; git config --global user.name '$user_git_name'; git config --global user.email '$user_git_email'",
    provider => 'shell',
    user => $user,
    cwd => "/home/${user}/",
    require => [Package['git-pack'], User['main-user']],
  }

  # check git access
  exec { 'git-test':
    path => '/usr/bin:/bin',
    provider => 'shell',
    command => "bash -c 'source /home/${user}/.ssh/environment; expect -c \'ssh -T git@github.com\''",
    require => [Package['git-pack'], User['main-user'], Class['dopki']],
  }

  # check out or update all the repos
  create_resources(docommon::getrepo, $repos, $repos_default)

}
