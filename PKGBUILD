
pkgname=proot-avm
pkgver=1.0.0
pkgdesc="Alpine Linux VM Manager for Termux with Docker support"
depends=('proot-distro' 'qemu-system-x86_64' 'qemu-utils' 'wget' 'curl' 'openssh')
url="https://github.com/ghost-chain-unity/proot-avm"

package() {
    # Install scripts
    install -Dm755 scripts/alpine-start.sh "$pkgdir/usr/bin/alpine-start"
    install -Dm755 scripts/alpine-vm.sh "$pkgdir/usr/bin/alpine-vm"

    # Create symlink for avm command
    ln -s /usr/bin/alpine-vm "$pkgdir/usr/bin/avm"

    # Install setup script
    install -Dm755 scripts/setup.sh "$pkgdir/usr/bin/proot-avm-setup"
}
