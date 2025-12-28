# proot-avm Documentation Website

This directory contains the GitHub Pages website for proot-avm, a modern Alpine Linux VM manager for Termux.

## 📁 Files Structure

```
docs/
├── index.html          # Main website
├── styles.css          # Modern CSS styling
├── script.js           # Interactive JavaScript
├── README.md           # This file
└── favicon.ico         # Website icon (to be added)
```

## 🚀 Features

- **Clean & Modern Design**: Professional dark theme with smooth animations
- **Responsive**: Works perfectly on desktop, tablet, and mobile
- **Interactive**: Copy-to-clipboard, smooth scrolling, toast notifications
- **Comprehensive**: All installation methods, documentation links, requirements
- **Fast**: Optimized for performance with minimal dependencies

## 🎨 Design Philosophy

- **Profound**: Deep, meaningful design that reflects the power of the tool
- **Clean**: Minimalist interface focused on content and functionality
- **Modern**: Latest web technologies with smooth animations
- **Accessible**: Proper contrast, keyboard navigation, screen reader support

## 🛠️ Technologies Used

- **HTML5**: Semantic markup with modern features
- **CSS3**: Custom properties, Grid, Flexbox, animations
- **JavaScript (ES6+)**: Modern JavaScript with classes and async/await
- **Font Awesome**: Beautiful icons
- **Google Fonts**: Inter font family for typography

## 📱 Responsive Breakpoints

- **Desktop**: > 768px
- **Tablet**: 480px - 768px
- **Mobile**: < 480px

## 🎯 Key Sections

1. **Hero**: Welcome message with quick install options
2. **Installation**: All installation methods with copy buttons
3. **Features**: Key features showcase
4. **Requirements**: System requirements and dependencies
5. **Documentation**: Links to all documentation files

## 🔗 Important Links

All links in the website point to the correct GitHub repository locations:

- Repository: `https://github.com/ghost-chain-unity/proot-avm`
- Raw scripts: `https://raw.githubusercontent.com/ghost-chain-unity/proot-avm/main/`
- Releases: `https://github.com/ghost-chain-unity/proot-avm/releases`

## 🧪 Testing

To test the website locally:

```bash
# Install a local server (if not available)
python3 -m http.server 8000

# Or using Node.js
npx serve .

# Or using PHP
php -S localhost:8000

# Then visit http://localhost:8000/docs/
```

## 🚀 Deployment

The website is automatically deployed to GitHub Pages when pushed to the `main` branch.

**GitHub Pages URL**: `https://ghost-chain-unity.github.io/proot-avm/`

## 📝 Development

### Adding New Sections

1. Add HTML structure to `index.html`
2. Add corresponding CSS to `styles.css`
3. Add interactivity to `script.js` if needed
4. Test responsiveness on different screen sizes

### Color Scheme

The website uses CSS custom properties for easy theming:

```css
:root {
    --primary-color: #6366f1;
    --bg-primary: #0f0f23;
    --text-primary: #ffffff;
    /* ... more variables */
}
```

### Animations

- **Fade In Up**: Elements animate in when scrolled into view
- **Hover Effects**: Subtle transforms and color changes
- **Terminal Animation**: Simulated typing effect
- **Toast Notifications**: Smooth slide-in/out

## 🔧 Maintenance

### Updating Links

When updating script locations or repository URLs:

1. Update all references in `index.html`
2. Test all links work correctly
3. Update this README if needed

### Adding New Installation Methods

1. Add new card to installation grid
2. Include appropriate icon and styling
3. Add copy functionality if needed
4. Test on all platforms

## 📊 Performance

- **Lighthouse Score**: Target 90+ on all metrics
- **Bundle Size**: Keep CSS and JS optimized
- **Load Time**: Fast loading with minimal dependencies
- **Accessibility**: WCAG 2.1 AA compliant

## 🤝 Contributing

To contribute to the website:

1. Follow the existing code style
2. Test on multiple browsers and devices
3. Ensure accessibility compliance
4. Add comments for complex functionality
5. Update this README for significant changes

## 📄 License

This website documentation is part of the proot-avm project and is licensed under the MIT License.

---

**Built with ❤️ for the proot-avm community**