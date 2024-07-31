#!/usr/bin/env bash
# shellcheck shell=bash
set -uex -o pipefail

workDir=$(mktemp -d)
trap 'rm -rf "${workDir}"' EXIT

echo "${HOSTS}" | jq -c '.[]' | while read -r host; do
    system_path=$(echo "${host}" | jq -r '.nixos_system')
    target_host=$(echo "${host}" | jq -r '.target_host')
    target_user=$(echo "${host}" | jq -r '.target_user')
    target_port=$(echo "${host}" | jq -r '.target_port')
    ssh_private_key=$(echo "${host}" | jq -r '.ssh_private_key')
    healthcheck_script=$(echo "${host}" | jq -r '.healthcheck_script')
    ignore_systemd_errors=$(echo "${host}" | jq -r '.ignore_systemd_errors')
    # 1. Copy closure
    # 2. Activate
    # Re-use nixos-anywhere for now
    "${MODULEPATH}"/deploy-host.sh "${system_path}" "${target_user}" "${target_host}" "${target_port}" "${ignore_systemd_errors}"

    # 3. Run healthcheck
    sshOpts=(-p "${target_port}")
    sshOpts+=(-o UserKnownHostsFile=/dev/null)
    sshOpts+=(-o StrictHostKeyChecking=no)
    if [[ -n ${SSH_KEY+x} && ${SSH_KEY} != "-" ]]; then
        sshPrivateKeyFile="${workDir}/ssh_key"
        # Create the file with 0700 - umask calculation: 777 - 700 = 077
        (
            umask 077
            echo "${SSH_KEY}" >"${sshPrivateKeyFile}"
        )
        unset SSH_AUTH_SOCK # don't use system agent if key was supplied
        sshOpts+=(-o "IdentityFile=${ssh_private_key}")
    fi
    target="${target_user}@${target_port}"

    ssh "${sshOpts[@]}" "${target}" "bash -s" < "${healthcheck_script}" || healthcheck_status="$?"
    if [[ $healthcheck_status != 0 ]]; then
        echo "healthcheck script failed with status ${healthcheck_status}"
        echo "rollbacking to previous NixOS system closure"
        remote_profiles=$(ssh -n "${sshOpts[@]}" "${target}" "ls /nix/var/nix/profiles")
        # We already activated the new profile.
        # Let's list all the available profiles on the machine and take the second to last.
        # shellcheck disable=SC2010
        previous_system="/nix/var/nix/profiles/$(echo "${remote_profiles}" | grep -e "system-[0-9]*-link" | sort | tail -2 | head -1)"
        rollback_command="${previous_system}/bin/switch-to-configuration switch"
        if [[ $target_user != "root" ]]; then
            rollback_command="sudo bash -c '${rollback_command}'"
        fi
        # shellcheck disable=SC2029
        ssh "${sshOpts[@]}" "${target}" '${rollback_command}'
        echo "System rollbacked to previous generation"
        exit 1
    fi
done
