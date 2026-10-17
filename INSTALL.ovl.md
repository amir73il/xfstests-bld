# Updating the overlay test VM

Procedure for refreshing the kvm-xfstests appliance on `overlayfs-devel`.
Stop any running appliance first. The image that gets booted is
`test-appliance/root_fs.img.amd64`.

`config.custom` already selects the trixie chroot and a networked image:

    BUILD_ENV="schroot -c trixie-amd64 --"
    SUDO_ENV="schroot -c trixie-amd64 -u root --"
    gen_image_args="--networking"

`fstests-bld/xfstests-dev` stays on `ovl-fixes`. This procedure builds
only that tree. It does not run `get-all` or rebuild fio, xfsprogs,
or the other dependencies.

## Update the files in the root tree

`test-appliance/gen-image` unpacks `test-appliance/files/` onto the
appliance root. The LTP and selftest binaries below are gitignored.
Refresh them before rebuilding the image.

LTP tests run by `test-appliance/files/root/ltp/runltp.sh`, from a
built `/home/amir/src/ltp`:

    ltp=/home/amir/src/ltp/testcases/kernel/syscalls
    dst=test-appliance/files/root/ltp
    install -m 755 $ltp/fcntl/fcntl3{8,9} $dst/fcntl/
    install -m 755 $ltp/inotify/inotify0{1,2,3,4,5,6,7,8} \
        $ltp/inotify/inotify1{0,1,2} $dst/inotify/
    install -m 755 $ltp/fanotify/fanotify{01,02,03,04,05,06,07,08,09,10} \
        $ltp/fanotify/fanotify{11,12,13,14,15,16,17,18,19,20} \
        $ltp/fanotify/fanotify{21,22,23,24,25,26} \
        $ltp/fanotify/fanotify_child $dst/fanotify/

Selftests run by `test-appliance/files/root/selftests/runselftests.sh`.
Build them in the kernel tree and install them under the same relative
paths. `mount-notify_test`, `mount-notify_test_ns`, and `ns-notify_test`
come from `tools/testing/selftests/filesystems/fanotify` on
`fan_mark_userns`. The overlay programs, including `automount_in_layer`,
come from `tools/testing/selftests/filesystems/overlayfs`.

    k=$HOME/src/linux
    make -C $k/tools/testing/selftests/filesystems/fanotify
    make -C $k/tools/testing/selftests/filesystems/overlayfs

    ss=test-appliance/files/root/selftests/filesystems
    install -m 755 $k/tools/testing/selftests/filesystems/fanotify/mount-notify_test \
        $k/tools/testing/selftests/filesystems/fanotify/mount-notify_test_ns \
        $k/tools/testing/selftests/filesystems/fanotify/ns-notify_test \
        $ss/fanotify/
    install -m 755 $k/tools/testing/selftests/filesystems/overlayfs/dev_in_maps \
        $k/tools/testing/selftests/filesystems/overlayfs/idmapped_mounts \
        $k/tools/testing/selftests/filesystems/overlayfs/automount_in_layer \
        $k/tools/testing/selftests/filesystems/overlayfs/set_layers_via_fds \
        $ss/overlayfs/

`fstests-bld/unionmount-testsuite` is the tree that gets installed.
`gen-tarball` copies it to `/root/xfstests/src/unionmount-testsuite`.
The copy under `test-appliance/files/root/unionmount-testsuite` is not
used.

FUSE passthrough binaries come from `$HOME/src/libfuse/build`. Each
config runs the binary named by its `FUSE_SUBTYP`, so install them on
`PATH`. `passthrough_fs` also needs `libfuse_passthrough`.

Install the canonical `xfstests/mount.fuse.passthrough` helper under
each subtype name. The helper derives the binary name from its own name.

Do not create top-level `sbin` or `lib` under `files/`. Unpacking them
would replace the `/sbin` and `/lib` symlinks in the image.

    fuse=$HOME/src/libfuse
    mkdir -p test-appliance/files/usr/bin test-appliance/files/usr/sbin
    install -m 755 $fuse/build/example/passthrough{,_ll,_hp,_fs} \
        test-appliance/files/usr/bin/
    libdir=test-appliance/files/usr/lib
    mkdir -p $libdir
    cp -a $fuse/build/lib/libfuse3.so.4 \
        $fuse/build/lib/$(readlink $fuse/build/lib/libfuse3.so.4) \
        $libdir/
    cp -a $fuse/build/passthrough/libfuse_passthrough.so.3 \
        $fuse/build/passthrough/$(readlink $fuse/build/passthrough/libfuse_passthrough.so.3) \
        $libdir/
    for subtype in passthrough passthrough_ll passthrough_hp passthrough_fs; do
        install -m 755 $fuse/xfstests/mount.fuse.passthrough \
            test-appliance/files/usr/sbin/mount.fuse.$subtype
    done

## Build the xfstests tarball

Build `xfstests-dev` in the trixie chroot, linking against the static
libraries in `bld/lib`. `gen-tarball` then runs `make install` in
`xfstests-dev` and adds the unionmount suite.

    cd fstests-bld
    schroot -c trixie-amd64 -- ./build-all --xfstests-only --clean-first
    schroot -c trixie-amd64 -- ./gen-tarball --arch amd64

The result is `fstests-bld/xfstests.tar.gz`.

## Rebuild the image

Copy the current image to `/var/lib/libvirt/images/kvm-xfstests/` before
replacing it. `gen-image --update` rewrites `test-appliance/root_fs.img.amd64`
in place, so this copy is the rollback copy.

    cp -a test-appliance/root_fs.img.amd64 \
        /var/lib/libvirt/images/kvm-xfstests/root_fs.img.amd64.$(date +%F)

`gen-image --update` keeps the existing Debian root. It unpacks the new
tarball under `/root` and copies `test-appliance/files/` over the same
tree. The image written is `test-appliance/root_fs.img.amd64`.

    cd test-appliance
    schroot -c trixie-amd64 -u root -- ./gen-image --networking --update \
        --src_date @$(git -C .. log -1 --pretty=%ct)

## Run

    kvm-xfstests ltp
    kvm-xfstests selftests
