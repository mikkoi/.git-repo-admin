#!/usr/bin/env bash

ref="${1}"
if [[ -z "${ref}" ]]; then ref='HEAD'; fi

if [[ ! $(command -v git) ]]; then
    echo "Cannot find command 'git'. Exiting ..."
    exit 1
fi
# Eliminate the effects of system wide and global configuration.
if [[ ! $(GIT_CONFIG_NOSYSTEM=1 XDG_CONFIG_HOME="" HOME="" \
        \git rev-parse --is-inside-git-dir) ]]; then
    echo "You can only run this script when inside a bare repo"
    exit 1
fi

admin_dir=".git-repo-admin"
\mkdir -p "${admin_dir}"
files=(
    install-server-hooks.sh
    install-hooks-functions.sh
    config
    VERSION
    githooks.pl
    cpanfile.server
)
for file in "${files[@]}"; do
    echo "Copy ${file} from repo (ref ${ref}) to local dir"
    \git cat-file -p "${ref}:${admin_dir}/${file}" > "${admin_dir}/${file}"
    # Set executable flags where proper
    if [[ "${admin_dir}/${file}" =~ ^.*\.(pl|sh)$ ]]; then
        chmod +x "${admin_dir}/${file}"
    fi
done
exec "${admin_dir}/install-server-hooks.sh" --install
