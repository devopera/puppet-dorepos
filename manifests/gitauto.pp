class dorepos::gitauto (

  # class arguments
  # ---------------
  # setup defaults

  $user = 'web',
  $script_download_path = 'https://raw.github.com/git/git/master/contrib/completion/git-completion.bash',
  $script_name = '.git-completion.bash',

  # end of class arguments
  # ----------------------
  # begin class

) {

  # download git-autocomplete script to home directory
  exec { 'dorepos-gitauto-download' :
    path => '/bin:/usr/bin:/sbin:/usr/sbin',
    command => "wget ${script_download_path} -O /home/${user}/${script_name} && chmod 0700 /home/${user}/${script_name}",
    creates => "/home/${user}/${script_name}",
    user => $user,
    group => $user,
    require => [User['main-user']],
  }

  # append to bashrc
  $command_bash_include_gitauto = "\n# activate git auto-completion if present\nif [ -f /home/${user}/.git-completion.bash ]; then\n        source /home/${user}/.git-completion.bash\nfi\n"
  concat::fragment { 'docommon-bashrc-gitauto':
    target  => "/home/${user}/.bashrc",
    content => $command_bash_include_gitauto,
    order   => '30',
    require => [Exec['dorepos-gitauto-download']], 
  }

}
