# functions in this file assume the existence of the following variables:

# folder where the drive's partition should be mounted
# can be initialized with `mountpoint_setup`
mountpoint=""

# device of the drive's partition (like /dev/sdc1)
# not initialized in this file, must be provided otherwise
partition=""


function check_continue() {
    read -r -p "do you still want to proceed? [yN]: " choice
    case "$choice" in
        y|Y|yes|YES);;
        *)
            echo "aborting"
            exit 10;;
    esac
}

function cmd() {
    echo "[DEBUG] >>> $*"
    "$@"
}

function run_as_root() {
  if [ "$(id -u)" -ne 0 ]; then
      echo "[INFO] rerunning this script as root"
      sudo -E bash "$0" "$@"
      exit $?
  fi
}

function mountpoint_setup() {
    mountpoint="$(mktemp -d)"
    export mountpoint
    trap 'rmdir "$mountpoint" &> /dev/null || true' EXIT
}

function partition_check_exists() {
    if [ ! -e "$partition" ] ; then
        echo "[FATAL] Unknown partition $partition"
        exit 2
    fi
}

function partition_is_luks() {
    cryptsetup isLuks "$partition" && echo "y" || echo "n"
}

function partition_get_size() {
    local partition_size
    partition_size=$(lsblk -nblo size "$partition")
    echo $(( partition_size / 1073741824 ))
}

function partition_get_label() {
    lsblk -nblo label "$partition"
}

function partition_format_luks() {
    cmd cryptsetup luksFormat "$partition"
}

function partition_format_ext4() {
    cmd mkfs.ext4 /dev/mapper/recovery
}

function partition_open() {
    cmd cryptsetup luksOpen "$partition" recovery
}

function partition_close() {
    cmd cryptsetup luksClose recovery
}

function partition_mount() {
    cmd mount /dev/mapper/recovery "$mountpoint"
}

function partition_umount() {
    cmd umount "$mountpoint"
}
