#! /bin/bash -e

function usage() {
    if [[ $# -ne 0 ]]; then
        printf '\E[31m'; echo "$@"; printf '\E[0m' >&2
    fi
    echo "usage: $0 [user1] [user2] ..." >&2
}
if [[ $EUID -eq 0 ]]; then
    usage "This script cannot be run using sudo or as the root user"
    exit 1
fi

if [[ $# -eq 0 ]]; then
    usage "No positional arguments specified"
    exit 1
fi

source .env || true

if [[ -z ${RASPBERRY_HOST} ]]; then
    usage "Environment variable RASPBERRY_HOST not set"
    exit 1
fi 

echo "Generating ssh key"
ssh-keygen -f .../keys/id_rsa -q -N "" <<< y > /dev/null
echo "SSH key generated in ~/.ssh/id_rsa"

for usr in "$@"; do
    echo "Copying ssh key for $usr"
    ssh-copy-id -i ../keys/id_rsa.pub $usr@$RASPBERRY_HOST
    ssh $usr@raspberry.local 'echo "ok from raspberry". user: $(whoami)'
done
