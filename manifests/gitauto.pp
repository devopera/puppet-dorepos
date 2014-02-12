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
    command => "curl ${script_download_path} -o /home/${user}/${script_name} && chmod 0700 /home/${user}/${script_name}",
    creates => "/home/${user}/${script_name}",
    user => $user,
    group => $user,
    require => [User['main-user']],
  }

  # append to bashrc
  exec { 'dorepos-gitauto-activate':
    path => '/bin:/usr/bin:/sbin:/usr/sbin',
    command => "echo \"\n# activate git auto-completion \nsource /home/${user}/${script_name}\" >> /home/${user}/.bashrc",
    onlyif  => "grep -q 'source /home/${user}/${script_name}' /home/${user}/.bashrc; test $? -eq 1",
    user    => $user,
  }

}
