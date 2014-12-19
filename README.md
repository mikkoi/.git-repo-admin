
# *.git-repo-admin*

Automate the maintenance of [Git hooks](http://git-scm.com/docs/githooks),
both local and central (bare) repository.
The hooks are executed under [Git::Hooks](https://metacpan.org/release/Git-Hooks) framework.

## What Does *.git-repo-admin* Do?

It tries to fulfill several demands:

* Simplify the adoption, maintenance and execution of Git hooks.
* Automate the updating of hooks in a system with multiple users.
* Handle updates with no action required from user.
* Minimize effect to user's local system.
  * This is especially important since Git::Hooks framework is created in Perl,
    and the required libraries must be held separate from user's *system Perl*.

## How Does it Do it?

* A simple initialization: one script for user to run. Should be run immediately after *Git clone*.
* Automatic updates: The hook reruns the initialization script at every *Git pull*.
* Uses Perl tools Plenv and Carton to isolate the Perl installation and keep it apart from system Perl, thus not "polluting" the module namespace.

## Requirements

* At least Git 1.7.10, because the config option *include.path* is used.

## Used technology

* [Git::Hooks](https://metacpan.org/release/Git-Hooks) framework
* [Carton](https://metacpan.org/pod/distribution/Carton/script/carton)
* [plenv](https://github.com/tokuhirom/plenv)
* [Perl programming language](http://www.perl.org)

# Usage

## Local Repository Installation

1. Copy the directory *.git-repo-admin* to the root of your repository.
2. Place your Git::Hooks configuration to file *.git-repo-admin/config_hooks.local*.
   You can start by copying the file *.git-repo-admin/config_hooks.example* and modifying it.
   Place your additional hooks (other programs, not Git::Hooks hooks) to the directory 
   *.git-repo-admin/hooks.d.local* and the subdirectory according to the Git hook you want to execute it with,
   e.g. pre-commit, commit-msg, etc.
   If your hooks need additional software installed:
   * Place all Perl module requirements into file *.git-repo-admin/cpanfile* together with their exact required versions.
      Execute *carton install* and they will be downloaded and configuration put into file *.git-repo-admin/cpanfile.snapshot*.
      Commit this file because it will be used by the next person installing or updating their hooks.
      (If you haven't got *carton* available yet, it will become so after you initialize the hooks (step 4.).
   * Place all other requirements into the script *.git-repo-admin/InitializeHooksLocal.pm*.
      You can start by copying the file *.git-repo-admin/InitializeHooksLocal.pm.example* and modifying it.
3. Commit the directory, including your changes. (Not necessary if you just want the hooks for yourself.
   In that case, add the directory name to file *.gitignore*.)
4. Execute script *.git-repo-admin/initialize-hooks.sh*.
5. The next time you pull from repo, the script *.git-repo-admin/hooks.d.local/post-merge/re-initialize-hooks.sh*
   will automatically run the initializing script and update your installation if necessary.

## Central (Bare) Repository Installation

This is more tricky because the bare repo normally doesn't have a working directory.

1. Copy the directory *.git-repo-admin* to the root of your repository.
2. Place your hook configuration to file *.git-repo-admin/config_hooks_user.central*.
   (follow instructions as in Local installation; Use file *.git-repo-admin/InitializeHooksCentral.pm* for other software.)
3. Commit the directory.
4. Checkout your central repo to a local directory, preferably next to the central repo.
E.g. *git clone --local file://repo.git repo.hooks*

5. Execute script *.git-repo-admin/initialize-hooks.sh* with parameter *--central*.
6. Have problems with *.git-repo-admin/git-hooks.sh* in finding all the paths and command executables?
   Put the necessary stuff in file *.git-repo-admin/git-hooks-aux.sh*.
   You can start by copying the file *.git-repo-admin/git-hooks-aux.sh.example* and modifying it.

# Copyright & Licensing

This software is copyright (c) 2014 by Mikko Koivunalho.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Please see file LICENSE.

