[devopera](http://devopera.com)-[dorepos](http://devopera.com/module/dorepos)
=======

Checkout and update repositories, optionally using Devopera public-key infrastructure (PKI)

Changelog
---------

2014-01-15

  * replaced nested $repo with $repo_X vars to handle defaults properly

2013-10-16

  * getrepo doesn't automatically force submodules on to their master branch, but installapp would if its $repo were not overridden

2013-10-04

  * stopped forcing permissions by default on checked out shell scripts to +x, because git stores exec permissions in the repo

2013-09-20

  * dorepos::installapp can now install apps with their own cron tasks.  By default install_crontabs = false, but it can be set using a resource collector or resource default if you have some kind of cron/automate profile.

2013-09-17

  * by default, when checking out a repo with submodules, put all submodules on to their master branch

2013-08-26

  * added symlinkdir feature to allow installed repos to put a symlink in another named folder, such as the user's home directory

2013-06-20

  * git pull now does a git submodule update too

2013-05-17

  * Changed \; to \\; as puppet recognised former as incorrect escaping

Usage
-----

Setup dorepos, initially with an empty list of repositories (no repos checked out)

    class { 'dorepos' :
      user => 'web',
      user_git_name => 'devopera',
      user_git_email => 'devopera@example.com',
      require => [Class['dopki'], Class['dopki::sshagentadd']],
    }

After setup, checkout a repo

    dorepos::getrepo { 'devopera-docommon-puppet-repo':
      user => 'web',
      provider => 'git',
      path => '/var/www/git/github.com',
      source => 'git@github.com:devopera/puppet-docommon.git',
      require => [Class['dorepos'], File['/var/www/git/github.com/']],
    }


Copyright and License
---------------------

Copyright (C) 2012 Lightenna Ltd

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
