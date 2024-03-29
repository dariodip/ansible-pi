#! /bin/bash -e

function usage() {
    if [[ $# -ne 0 ]]; then
        printf '\E[31m'; echo "$@"; printf '\E[0m' >&2
    fi
    echo "usage: sudo $0 [disk]" >&2
}

RPI_OS_IMAGE="raspberry_os.img"
RPI_OS_IMAGE_ZIP="$RPI_OS_IMAGE.zip"
RPI_OS_IMAGE_URL=${RPI_OS_IMAGE_URL:-https://downloads.raspberrypi.org/raspbian_lite_latest}
UNZIP_CMD=${UNZIP_CMD:-"unzip"}
DISK_PARTITION=$1

if [[ $EUID -ne 0 ]]; then
    usage "This script should be run using sudo or as the root user"
    exit 1
fi

if [[ $# -eq 0 ]]; then
    usage "No positional arguments specified"
    exit 1
fi

set +e

diskutil list | grep $DISK_PARTITION >> /dev/null && 
    echo $DISK_PARTITION | grep -q -E '/dev/disk[0-9]'

if [[ $? -ne 0 ]]; then
    usage "$DISK_PARTITION is not a disk"
    exit 1
fi
echo "Installing Raspbian on $DISK_PARTITION" 

test -f $RPI_OS_IMAGE

if [[ $? -eq 0 ]]; then
    echo "$RPI_OS_IMAGE found in $(pwd)"
else
    which wget > /dev/null
    if [[ $? -ne 0 ]]; then
        echo "wget not installed" >&2
        exit 1
    fi
    echo "Downloading raspbian image to $RPI_OS_IMAGE_ZIP from $RPI_OS_IMAGE_URL"
    wget -O $RPI_OS_IMAGE_ZIP $RPI_OS_IMAGE_URL >&1

    which $UNZIP_CMD > /dev/null
    if [[ $? -ne 0 ]]; then
        echo "wget not installed" >&2
        exit 1
    fi
    echo "Unzipping $RPI_OS_IMAGE_ZIP"
    $UNZIP_CMD $RPI_OS_IMAGE_ZIP

    rm $RPI_OS_IMAGE_ZIP

    find . -type f -iname "*.img" -exec mv {} $RPI_OS_IMAGE \;
fi
set -e

OUTPUT_PARTITION=$(echo $DISK_PARTITION | sed -e 's#/dev/disk\([0-9]*\)#/dev/rdisk\1#g')

diskutil unmountDisk $DISK_PARTITION
echo "Writing on $OUTPUT_PARTITION"
sudo dd bs=1m if=$RPI_OS_IMAGE of=$OUTPUT_PARTITION conv=sync 

echo "Ejecting $DISK_PARTITION"
sudo diskutil eject $OUTPUT_PARTITION

echo "Done"
