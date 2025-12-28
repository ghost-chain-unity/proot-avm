// proot-avm Website Script
// Clean, modern, and profound interactions

class ProotAVMWebsite {
    constructor() {
        this.init();
    }

    init() {
        this.setupEventListeners();
        this.setupScrollAnimations();
        this.setupTerminalAnimation();
        this.setupMobileNavigation();
    }

    setupEventListeners() {
        // Copy to clipboard functionality
        document.querySelectorAll('.copy-btn').forEach(btn => {
            btn.addEventListener('click', (e) => this.copyToClipboard(e));
        });

        // Smooth scrolling for navigation links
        document.querySelectorAll('a[href^="#"]').forEach(link => {
            link.addEventListener('click', (e) => this.smoothScroll(e));
        });

        // Platform download buttons
        document.querySelectorAll('.platform-btn').forEach(btn => {
            btn.addEventListener('click', (e) => this.handleDownload(e));
        });
    }

    copyToClipboard(event) {
        const button = event.currentTarget;
        const codeBlock = button.closest('.code-block');
        const code = codeBlock.querySelector('code').textContent;

        navigator.clipboard.writeText(code).then(() => {
            this.showToast('Command copied to clipboard!');
        }).catch(err => {
            console.error('Failed to copy: ', err);
            // Fallback for older browsers
            this.fallbackCopyTextToClipboard(code);
        });
    }

    fallbackCopyTextToClipboard(text) {
        const textArea = document.createElement('textarea');
        textArea.value = text;
        textArea.style.position = 'fixed';
        textArea.style.left = '-999999px';
        textArea.style.top = '-999999px';
        document.body.appendChild(textArea);
        textArea.focus();
        textArea.select();

        try {
            document.execCommand('copy');
            this.showToast('Command copied to clipboard!');
        } catch (err) {
            console.error('Fallback copy failed: ', err);
            this.showToast('Failed to copy command', 'error');
        }

        document.body.removeChild(textArea);
    }

    showToast(message, type = 'success') {
        const toast = document.getElementById('toast');
        const toastMessage = document.getElementById('toast-message');
        const toastIcon = toast.querySelector('i');

        toastMessage.textContent = message;

        // Update icon based on type
        if (type === 'error') {
            toastIcon.className = 'fas fa-exclamation-circle';
            toastIcon.style.color = 'var(--error-color)';
        } else {
            toastIcon.className = 'fas fa-check-circle';
            toastIcon.style.color = 'var(--success-color)';
        }

        toast.classList.add('show');

        setTimeout(() => {
            toast.classList.remove('show');
        }, 3000);
    }

    smoothScroll(event) {
        event.preventDefault();
        const targetId = event.currentTarget.getAttribute('href');
        const targetElement = document.querySelector(targetId);

        if (targetElement) {
            const offsetTop = targetElement.offsetTop - 80; // Account for fixed navbar
            window.scrollTo({
                top: offsetTop,
                behavior: 'smooth'
            });
        }
    }

    handleDownload(event) {
        const button = event.currentTarget;
        const platform = button.textContent.trim();
        const url = button.href;

        // Track download (you can integrate with analytics here)
        console.log(`Download initiated: ${platform} - ${url}`);

        // Show download started message
        this.showToast(`Downloading ${platform}...`);
    }

    handleBinaryDownload(event, platform) {
        // Check if the binary exists (this is a simple check)
        fetch(event.currentTarget.href, { method: 'HEAD' })
            .then(response => {
                if (response.ok) {
                    this.showToast(`Downloading ${platform} binary...`);
                } else {
                    // Binary not found, redirect to releases page
                    event.preventDefault();
                    window.open('https://github.com/ghost-chain-unity/proot-avm/releases', '_blank');
                    this.showToast('Redirecting to releases page...', 'info');
                }
            })
            .catch(() => {
                // Network error or binary not available
                event.preventDefault();
                window.open('https://github.com/ghost-chain-unity/proot-avm/releases', '_blank');
                this.showToast('Binary not available yet. Redirecting to releases...', 'info');
            });
    }

    setupScrollAnimations() {
        const observerOptions = {
            threshold: 0.1,
            rootMargin: '0px 0px -50px 0px'
        };

        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.add('fade-in-up');
                }
            });
        }, observerOptions);

        // Observe all sections for scroll animations
        document.querySelectorAll('section > .container').forEach(section => {
            observer.observe(section);
        });

        // Observe individual cards
        document.querySelectorAll('.install-card, .feature-card, .requirement-card, .doc-card').forEach(card => {
            observer.observe(card);
        });
    }

    setupTerminalAnimation() {
        const terminalContent = document.querySelector('.terminal-content');
        if (!terminalContent) return;

        const lines = terminalContent.querySelectorAll('.terminal-line');
        let currentLine = 0;

        const animateLine = () => {
            if (currentLine < lines.length) {
                lines[currentLine].style.opacity = '1';
                currentLine++;

                // Random delay between lines (500ms to 1500ms)
                const delay = Math.random() * 1000 + 500;
                setTimeout(animateLine, delay);
            }
        };

        // Start animation after page load
        setTimeout(() => {
            animateLine();
        }, 1000);
    }

    setupMobileNavigation() {
        const navToggle = document.querySelector('.nav-toggle');
        const navLinks = document.querySelector('.nav-links');

        if (navToggle && navLinks) {
            navToggle.addEventListener('click', () => {
                navLinks.classList.toggle('active');
                navToggle.classList.toggle('active');

                // Animate hamburger menu
                const spans = navToggle.querySelectorAll('span');
                if (navToggle.classList.contains('active')) {
                    spans[0].style.transform = 'rotate(45deg) translate(5px, 5px)';
                    spans[1].style.opacity = '0';
                    spans[2].style.transform = 'rotate(-45deg) translate(7px, -6px)';
                } else {
                    spans[0].style.transform = 'none';
                    spans[1].style.opacity = '1';
                    spans[2].style.transform = 'none';
                }
            });

            // Close mobile menu when clicking a link
            navLinks.querySelectorAll('.nav-link').forEach(link => {
                link.addEventListener('click', () => {
                    navLinks.classList.remove('active');
                    navToggle.classList.remove('active');

                    const spans = navToggle.querySelectorAll('span');
                    spans[0].style.transform = 'none';
                    spans[1].style.opacity = '1';
                    spans[2].style.transform = 'none';
                });
            });
        }
    }

    // Utility function to scroll to section
    scrollToSection(sectionId) {
        const section = document.getElementById(sectionId);
        if (section) {
            const offsetTop = section.offsetTop - 80;
            window.scrollTo({
                top: offsetTop,
                behavior: 'smooth'
            });
        }
    }
}

// Utility functions for global use
function scrollToSection(sectionId) {
    const section = document.getElementById(sectionId);
    if (section) {
        const offsetTop = section.offsetTop - 80;
        window.scrollTo({
            top: offsetTop,
            behavior: 'smooth'
        });
    }
}

function copyCommand(command) {
    navigator.clipboard.writeText(command).then(() => {
        showToast('Command copied to clipboard!');
    }).catch(err => {
        console.error('Failed to copy: ', err);
        // Fallback copy
        const textArea = document.createElement('textarea');
        textArea.value = command;
        document.body.appendChild(textArea);
        textArea.focus();
        textArea.select();
        document.execCommand('copy');
        document.body.removeChild(textArea);
        showToast('Command copied to clipboard!');
    });
}

function showToast(message, type = 'success') {
    const toast = document.getElementById('toast');
    const toastMessage = document.getElementById('toast-message');
    const toastIcon = toast.querySelector('i');

    toastMessage.textContent = message;

    if (type === 'error') {
        toastIcon.className = 'fas fa-exclamation-circle';
        toastIcon.style.color = 'var(--error-color)';
    } else {
        toastIcon.className = 'fas fa-check-circle';
        toastIcon.style.color = 'var(--success-color)';
    }

    toast.classList.add('show');

    setTimeout(() => {
        toast.classList.remove('show');
    }, 3000);
}

// Performance optimization: Debounce scroll events
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// Update navbar on scroll
function updateNavbar() {
    const navbar = document.querySelector('.navbar');
    const scrolled = window.scrollY > 50;

    if (scrolled) {
        navbar.style.background = 'rgba(15, 15, 35, 0.98)';
        navbar.style.boxShadow = 'var(--shadow-md)';
    } else {
        navbar.style.background = 'rgba(15, 15, 35, 0.95)';
        navbar.style.boxShadow = 'none';
    }
}

// Initialize everything when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    // Initialize main website class
    new ProotAVMWebsite();

    // Setup scroll-based navbar updates
    const debouncedUpdateNavbar = debounce(updateNavbar, 10);
    window.addEventListener('scroll', debouncedUpdateNavbar);

    // Add loading animation
    document.body.classList.add('loaded');

    // Preload critical resources
    const link = document.createElement('link');
    link.rel = 'preload';
    link.href = 'styles.css';
    link.as = 'style';
    document.head.appendChild(link);

    console.log('🚀 proot-avm website loaded successfully!');
});

// Add some CSS for loading animation
const style = document.createElement('style');
style.textContent = `
    body {
        opacity: 0;
        transition: opacity 0.3s ease;
    }

    body.loaded {
        opacity: 1;
    }

    .terminal-line {
        opacity: 0;
        transition: opacity 0.3s ease;
    }

    .nav-links.active {
        display: flex !important;
        position: absolute;
        top: 100%;
        left: 0;
        right: 0;
        background: var(--bg-secondary);
        flex-direction: column;
        padding: var(--spacing-lg);
        border-top: 1px solid var(--border-color);
        box-shadow: var(--shadow-lg);
    }

    @media (min-width: 769px) {
        .nav-links.active {
            position: static;
            display: flex !important;
            background: transparent;
            box-shadow: none;
            border: none;
            padding: 0;
            flex-direction: row;
        }
    }
`;
document.head.appendChild(style);

function handleBinaryDownload(event, platform) {
    // Check if the binary exists
    fetch(event.currentTarget.href, { method: 'HEAD' })
        .then(response => {
            if (response.ok) {
                showToast(`Downloading ${platform} binary...`);
            } else {
                // Binary not found, redirect to releases page
                event.preventDefault();
                window.open('https://github.com/ghost-chain-unity/proot-avm/releases', '_blank');
                showToast('Redirecting to releases page...', 'info');
            }
        })
        .catch(() => {
            // Network error or binary not available
            event.preventDefault();
            window.open('https://github.com/ghost-chain-unity/proot-avm/releases', '_blank');
            showToast('Binary not available yet. Redirecting to releases...', 'info');
        });
}

// Export for potential use in other scripts
window.ProotAVMWebsite = ProotAVMWebsite;
window.scrollToSection = scrollToSection;
window.copyCommand = copyCommand;
window.showToast = showToast;
window.handleBinaryDownload = handleBinaryDownload;