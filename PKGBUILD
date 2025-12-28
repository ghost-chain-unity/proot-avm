
# Maintainer: ghost-chain-unity <ghost-chain-unity@github.com>
pkgname=proot-avm
pkgver=2.0.0
pkgrel=1
pkgdesc="Alpine Linux VM Manager for Termux with Docker support and Go CLI"
arch=('any')
license=('MIT')
depends=('proot-distro' 'qemu-system-x86_64' 'qemu-utils' 'wget' 'curl' 'openssh' 'bash')
optdepends=(
    'docker: Alternative container runtime'
    'podman: Alternative container runtime'
    'vncviewer: For VNC connections'
    'virt-manager: GUI VM management'
)
url="https://github.com/ghost-chain-unity/proot-avm"
source=("$pkgname-$pkgver.tar.gz::$url/archive/v$pkgver.tar.gz")
sha256sums=('SKIP')
backup=('etc/proot-avm/alpine-answers.txt' 'etc/proot-avm/sshd_config')

package() {
    cd "$pkgname-$pkgver"

    # Install main scripts
    install -Dm755 install.sh "$pkgdir/usr/bin/proot-avm-install"
    install -Dm755 install-one-liner.sh "$pkgdir/usr/bin/proot-avm-one-liner"
    install -Dm755 avm-go.sh "$pkgdir/usr/bin/avm-go"

    # Install core scripts
    install -Dm755 scripts/alpine-start.sh "$pkgdir/usr/bin/alpine-start"
    install -Dm755 scripts/alpine-vm.sh "$pkgdir/usr/bin/alpine-vm"
    install -Dm755 scripts/avm-agent.sh "$pkgdir/usr/bin/avm-agent"
    install -Dm755 scripts/enhanced-bootstrap.sh "$pkgdir/usr/bin/enhanced-bootstrap"
    install -Dm755 scripts/setup-alpine-auto.sh "$pkgdir/usr/bin/setup-alpine-auto"
    install -Dm755 scripts/shared-functions.sh "$pkgdir/usr/share/proot-avm/shared-functions.sh"

    # Install Go CLI binary (if available)
    if [ -f "avm-go/avm" ]; then
        install -Dm755 avm-go/avm "$pkgdir/usr/bin/avm"
    fi

    # Create symlink for avm command (prefer Go CLI if available)
    if [ -f "$pkgdir/usr/bin/avm" ]; then
        ln -sf /usr/bin/avm "$pkgdir/usr/bin/avm-bash"
    else
        ln -sf /usr/bin/alpine-vm "$pkgdir/usr/bin/avm"
        ln -sf /usr/bin/alpine-vm "$pkgdir/usr/bin/avm-bash"
    fi

    # Install configuration files
    install -Dm644 configs/alpine-answers.txt "$pkgdir/etc/proot-avm/alpine-answers.txt"
    install -Dm644 configs/sshd_config "$pkgdir/etc/proot-avm/sshd_config"

    # Install documentation
    install -Dm644 README.md "$pkgdir/usr/share/doc/$pkgname/README.md"
    install -Dm644 SETUP.md "$pkgdir/usr/share/doc/$pkgname/SETUP.md"
    install -Dm644 DEVELOPMENT.md "$pkgdir/usr/share/doc/$pkgname/DEVELOPMENT.md"
    install -Dm644 CONTRIBUTING.md "$pkgdir/usr/share/doc/$pkgname/CONTRIBUTING.md"
    install -Dm644 ROADMAP.md "$pkgdir/usr/share/doc/$pkgname/ROADMAP.md"

    # Install license
    install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"

    # Install test suite
    install -Dm755 test-installer.sh "$pkgdir/usr/share/proot-avm/test-installer.sh"

    # Install build scripts for development
    install -Dm755 build-binaries.sh "$pkgdir/usr/share/proot-avm/build-binaries.sh"
}
