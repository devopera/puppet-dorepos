dorepos
=======

Checkout and update repositories using devopera PKI

Changelog
---------

2013-09-17

 * by default, when checking out a repo with submodules, put all submodules on to their master branch

2013-08-26

 * added symlinkdir feature to allow installed repos to put a symlink in another named folder, such as the user's home directory

2013-06-20

 * git pull now does a git submodule update too

2013-05-17

 * Changed \; to \\; as puppet recognised former as incorrect escaping

Copyright and License
---------------------

Copyright (C) 2012 Lightenna Ltd

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
