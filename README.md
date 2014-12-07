
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

## Used technology

* [Git::Hooks](https://metacpan.org/release/Git-Hooks) framework
* [Carton](https://metacpan.org/pod/distribution/Carton/script/carton)
* [plenv](https://github.com/tokuhirom/plenv)
* [Perl programming language](http://www.perl.org)

# Usage

## Local Repository Installation

1. Copy the directory *.git-repo-admin* to the root of your repository.
2. Commit the directory. (Not necessary if you just want the hooks for yourself.)
3. Execute script *.git-repo-admin/initialize-hooks.sh*.

## Central (Bare) Repository Installation

This is more tricky because the bare repo normally doesn't have a working directory.

1. Copy the directory *.git-repo-admin* to the root of your repository.
2. Commit the directory.
3. Checkout your central repo to a local directory, preferably next to the central repo.
E.g. *git clone --local file://repo.git repo.hooks*
4. Execute script *.git-repo-admin/initialize-hooks.sh* with parameter *--central*.

# Copyright & Licensing

This software is copyright (c) 2014 by Mikko Koivunalho.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Please see file LICENSE.

