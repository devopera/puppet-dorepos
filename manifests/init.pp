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

  case $operatingsystem {
    centos, redhat, fedora,
    ubuntu, debian: {

      # configure git
      exec { 'git-config' :
        path => '/usr/bin:/bin',
        command => "export HOME=/home/${user}/; git config --global user.name '$user_git_name'; git config --global user.email '$user_git_email'; git config --global color.ui true",
        provider => 'shell',
        # do git config everytime
        # creates => "/home/${user}/.gitconfig",
        user => $user,
        cwd => "/home/${user}/",
        require => [Package['git'], User['main-user']],
      }

      # check git access
      exec { 'git-test':
        path => '/usr/bin:/bin',
        provider => 'shell',
        command => "bash -c 'source /home/${user}/.ssh/environment; expect -c \'ssh -T git@github.com\''",
        require => [Package['git'], User['main-user']],
      }

      # check out or update all the repos
      create_resources(dorepos::getrepo, $repos, $repos_default)
    }
    windows: {

      windows_env { 'dorepos-windows-env-git-ssh' :
        ensure    => present,
        variable  => 'GIT_SSH',
        value     => 'C:\ProgramData\chocolatey\lib\putty.portable\tools\PLINK.EXE',
        mergemode => clobber,
      }
      # this doesn't seem to work
      exec { 'dorepos-windows-git-name':
        command   => "git config --global user.name '$user_git_name'",
        provider  => powershell,
      }
      exec { 'dorepos-windows-git-email':
        command   => "git config --global user.email '$user_git_email'",
        provider  => powershell,
      }

    }
  }

}
