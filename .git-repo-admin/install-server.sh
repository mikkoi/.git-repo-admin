#!/usr/bin/env bash

if [[ ! $(command -v git) ]]; then
    echo "Cannot find command 'git'. Exiting ..."
    exit 1
fi
if [[ ! $(\git rev-parse --is-inside-git-dir) ]]; then
    echo "You can only run this script when inside a bare repo"
    exit 1
fi

admin_dir="git-repo-admin"
\mkdir -p "${admin_dir}"
files=(
    install-server-hooks.sh
    install-hooks-functions.sh
    config_hooks
    githooks.pl
    cpanfile
)
for file in "${files[@]}"; do
    echo "Copy ${file} from repo to local dir"
    \git show "HEAD:.git-repo-admin/${file}" > "${admin_dir}/${file}"
    # Set executable flags where proper
    if [[ "${admin_dir}/${file}" =~ ^.*(pl|sh)$ ]]; then
        chmod +x "${admin_dir}/${file}"
    fi
done
exec "${admin_dir}/install-server-hooks.sh" --install
