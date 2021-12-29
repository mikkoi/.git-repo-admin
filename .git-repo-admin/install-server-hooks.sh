#!/usr/bin/env bash

if [[ ! $(command -v git) ]]; then
    echo "Cannot find command 'git'. Exiting ..."
    exit 1
fi

if [[ ! $(\git rev-parse --is-inside-git-dir) ]]; then
    echo "You can only run this script when inside a bare repo"
    exit 1
fi

# Check args
action="$1"
uninstall_all="$2"
if [[ $action != "--install" && $action != "--uninstall" ]]; then
    echo "Usage: $0 <--install|--uninstall> <--all>"
    exit 1
fi
if [[ $uninstall_all != "" && $uninstall_all != "--all" ]]; then
    echo "Usage: $0 <--install|--uninstall> <--all>"
    exit 1
fi

# Discover where we are.
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done

# How to work with hooks in the server side, that is the question!
# Earlier we had a worktree checked out parallel to the actual repository.
# That was awfully clumsy and error prone!
# 

# On client side, this is Git working directory + .git-repo-admin dir.
# On server side, this is a subdirectory in the bare repo
# We will extract what we need from the bare repo to this dir.
admin_dir="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"
admin_dir="${admin_dir}"
# Git bare repo root directory
git_dir="$( cd -P "$( dirname "${SOURCE}" )/.." && pwd )"

declare hooks=( "pre-receive" "update" "post-receive" )

# shellcheck disable=SC1090
source "${admin_dir}/install-hooks-functions.sh"

if [[ $action = "--install" ]]; then
    # Hooks need Perl and Perl package manager CPAN.

    if ! command -v cpan >/dev/null 2>&1 ; then
        echo "Cannot continue. Need Perl program 'cpan'."
        exit 1
    fi

    # These hooks use Git::Hooks framework.
    # It is a Perl module, so we need to install it.
    # But we will install it locally to this same directory
    # to make sure we don't disturb system Perl.

    # We need to set all of these to install Perl module into our own separate dir.
    # This installation will depend only on system/current Perl.
    # N.B. If user has a ~/local Perl dir, it is skipped.

    our_perl_base="${admin_dir}/local"
    \mkdir -p "${our_perl_base}"
    export PERL_MM_OPT="INSTALL_BASE=${our_perl_base}"
    export PERL_MB_OPT="--install_base ${our_perl_base}"
    # export PERL5LIB="${our_perl_base}/lib/perl5${PERL5LIB:+:$PERLLIB}"
    export PERL5LIB="${our_perl_base}/lib/perl5"
    export PATH="${our_perl_base}/bin${PATH:+:$PATH}"
    export MANPATH="${our_perl_base}/man${MANPATH:+:$MANPATH}"

    # Collect requirements from cpanfile.
    declare dependencies=()
    mapfile -t dependencies < <(parse_cpanfile "${admin_dir}/cpanfile.server")
    echo "${dependencies[@]}"

    # Install dependencies
    for dep in "${dependencies[@]}"; do
        echo "Installing $dep ..."
        if ! PERL_MM_USE_DEFAULT=1 \cpan install "$dep"; then
            echo "Cannot continue. Failed to install dependency $dep."
            exit 1
        fi
    done

    # Link git-repo-admin/config to the local Git config
    if ! \git -C "$(pwd)" config --local --get-all include.path | grep --quiet "^${admin_dir}/config$"; then
        echo "Add include.path to Git config."
        \git -C "${git_dir}" config --local --add include.path "${admin_dir}/config"
    fi

    # Attach all client side hooks to Git::Hooks
    echo "Link hooks to Git::Hooks"
    for hook in "${hooks[@]}"; do
        install_hook "${git_dir}" "${admin_dir}" "${hook}"
    done
else
    # Uninstall
    # Actually, just disconnect!
    # We don't do anything with the local/ dir, or even use Perl.
    # We also do not delete any hooks in hooks.d/, but we move
    # the old hook, if any, back to its original place.
    
    # Detach all client side hooks: remove symlinks and return old hooks, if any.
    echo "Unlink hooks:"
    for hook in "${hooks[@]}"; do
        uninstall_hook "${git_dir}" "${admin_dir}" "${hook}"
    done

    # Link .git-repo-admin/config to the local Git config
    hooks_config_path="${admin_dir}/config"
    echo "Amend Git configuration:"
    if \git -C "$(pwd)" config --local --get-all include.path | grep --quiet "^${hooks_config_path}$"; then
        echo "Remove include.path from Git config."
        \git -C "${git_dir}" config --local --fixed-value --unset include.path "${hooks_config_path}"
    else
        echo "No changes to Git config."
    fi
    if [[ $uninstall_all = "--all" ]]; then
        \rm --recursive --force "${admin_dir}"
    fi
fi
