#!/usr/bin/env bash

if [[ ! $(command -v git) ]]; then
    echo "Cannot find command 'git'. Exiting ..."
    exit 1
fi
if [[ ! $(\git rev-parse --is-inside-work-tree) ]]; then
    echo "You can only run this script when inside a repo work-tree"
    exit 1
fi
if [[ ! -d .git || ! -d .git/hooks ]]; then
    echo "You can only run this script in the root of the repo"
    exit 1
fi

# Check args
action="$1"
if [[ $action != "--install" && $action != "--uninstall" ]]; then
    echo "Usage: $0 <--install|--uninstall>"
    exit 1
fi

# Discover where we are
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done

# Name of .git-repo-admin directory
admin_dir_name='.git-repo-admin'
# Git working directory + .git-repo-admin
admin_dir="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"
# Work tree, Git working directory
work_dir="$( cd -P "$( dirname "${SOURCE}" )/.." && pwd )"
# Git working directory + .git
git_dir="$( cd -P "$( dirname "${SOURCE}" )/../.git" && pwd )"
# Local admin dir, in .git/.
local_admin_dir="${git_dir}/${admin_dir_name}"

# shellcheck disable=SC1090
source "${admin_dir}/install-hooks-functions.sh"

declare client_side_hooks=(
    "pre-commit" "prepare-commit-msg" "commit-msg" "post-commit"
    "applypatch-msg" "pre-applypatch" "post-applypatch"
    "pre-rebase" "post-rewrite" "post-checkout" "post-merge"
    "pre-push" "pre-auto-gc"
)

if [[ $action = "--install" ]]; then
    # Start with creating the local "installation"
    echo "Create local installation at ${local_admin_dir}"
    \mkdir -p "${local_admin_dir}"
    files=(
        config
        VERSION
        githooks.pl
        )
    for file in "${files[@]}"; do
        echo "Copy ${file} from repo to local dir"
        \cp "${admin_dir}/${file}" "${local_admin_dir}"
        # Set executable flags where proper
        if [[ "${local_admin_dir}/${file}" =~ ^.*(pl|sh)$ ]]; then
            chmod +x "${local_admin_dir}/${file}"
        fi
    done

    # Hooks need Perl and Perl package manager cpan.
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

    our_perl_base="${local_admin_dir}/local"
    \mkdir -p "${our_perl_base}"
    export PERL_MM_OPT="INSTALL_BASE=${our_perl_base}"
    export PERL_MB_OPT="--install_base ${our_perl_base}"
    # export PERL5LIB="${our_perl_base}/lib/perl5${PERL5LIB:+:$PERLLIB}"
    export PERL5LIB="${our_perl_base}/lib/perl5"
    export PATH="${our_perl_base}/bin${PATH:+:$PATH}"
    export MANPATH="${our_perl_base}/man${MANPATH:+:$MANPATH}"

    # Collect requirements from cpanfile.
    declare dependencies=()
    mapfile -t dependencies < <(parse_cpanfile "${admin_dir}/cpanfile.client")

    # Install dependencies
    for dep in "${dependencies[@]}"; do
        echo "Installing $dep ..."
        if ! PERL_MM_USE_DEFAULT=1 \cpan install "$dep"; then
            echo "Cannot continue. Failed to install dependency $dep."
            exit 1
        fi
    done

    # Link .git-repo-admin/config to the local Git config
    hooks_config_path="./${admin_dir_name}/config"
    if ! \git -C "$(pwd)" config --local --get-all include.path | \
            \grep --quiet "^${hooks_config_path}$"; then
        echo "Add include.path to Git config."
        \git -C "${work_dir}" config --local --add include.path "${hooks_config_path}"
    fi

    # Attach all client side hooks to Git::Hooks
    echo "Link hooks to Git::Hooks"
    for hook in "${client_side_hooks[@]}"; do
        install_hook "${git_dir}" "../${admin_dir_name}" "${hook}"
    done
else
    # Uninstall
    # Actually, just disconnect!
    # We don't do anything with the local/ dir, or even use Perl.
    # We also do not delete any hooks in hooks.d/, but we move
    # the old hook, if any, back to its original place.
    
    # Detach all client side hooks: remove symlinks and return old hooks, if any.
    echo "Unlink hooks:"
    for hook in "${client_side_hooks[@]}"; do
        uninstall_hook "${git_dir}" "../${admin_dir_name}" "${hook}"
    done

    # unlink the configuration file
    hooks_config_path="./${admin_dir_name}/config"
    echo "Amend Git configuration:"
    if \git -C "$(pwd)" config --local --get-all include.path | \
            \grep --quiet "^${hooks_config_path}$"; then
        echo "Config include.path exists. Remove... "
        \git -C "${work_dir}" config --local --fixed-value --unset include.path "${hooks_config_path}"
    else
        echo "No changes to Git config."
    fi
fi
