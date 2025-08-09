# mTask - Modern Task Management for macOS

<div align="center">
  <img src="https://img.shields.io/badge/platform-macOS-blue" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-5.0+-orange" alt="Swift Version">
  <img src="https://img.shields.io/badge/SwiftUI-Latest-green" alt="SwiftUI">
  <img src="https://img.shields.io/badge/license-MIT-lightgrey" alt="License">
</div>

A beautifully designed, modern task management application for macOS built with SwiftUI. mTask combines elegant design with powerful functionality to help you stay organized and productive.

## ✨ Features

### 🎨 Modern Design
- **Beautiful UI**: Card-based design with subtle shadows and modern aesthetics
- **Dark/Light Mode**: Automatic support for macOS appearance preferences
- **Smooth Animations**: Delightful hover effects and transitions throughout
- **Consistent Typography**: Carefully crafted text hierarchy and spacing

### 📋 Task Management
- **Multiple Lists**: Organize tasks into different categories
- **Subtasks**: Create hierarchical task structures with indent/outdent
- **Due Dates**: Set deadlines with smart visual indicators
- **Notes**: Add detailed descriptions to any task
- **Quick Add**: Fast task creation with keyboard shortcuts

### 📊 Analytics & Insights
- **Progress Tracking**: Visual progress bars and completion percentages
- **Statistics Dashboard**: Comprehensive analytics with charts and breakdowns
- **Due Date Tracking**: Smart categorization of overdue, today, and upcoming tasks
- **Activity Overview**: Recent task activity and trends

### 🔄 Sync & Backup
- **Google Tasks Integration**: Sync with Google Tasks (coming soon)
- **Local Storage**: Reliable JSON-based persistence
- **Data Export**: Backup and restore your tasks

## 🖼️ Screenshots

*Screenshots coming soon - the app features a modern, clean interface with:*
- Elegant sidebar with task lists and statistics
- Card-based task rows with hover interactions
- Beautiful empty states with helpful tips
- Comprehensive statistics dashboard

## 🚀 Getting Started

### Prerequisites
- macOS 13.0 or later
- Xcode 14.0 or later
- Swift 5.7 or later

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/imvipgit/mTask.git
   cd mTask
   ```

2. **Open in Xcode**
   ```bash
   open mTask.xcodeproj
   ```

3. **Build and Run**
   - Select your target device/simulator
   - Press `Cmd + R` to build and run

## 🏗️ Architecture

mTask is built using modern SwiftUI patterns and follows MVVM architecture:

```
mTask/
├── Models/           # Data models and persistence
├── Views/            # SwiftUI views and components
├── Theme/            # Design system and styling
├── Sync/             # Synchronization engine
└── Assets.xcassets/  # Images and colors
```

### Key Components

- **AppStore**: Central state management for tasks and lists
- **ThemeManager**: Comprehensive design system with colors, typography, and spacing
- **TaskRowView**: Modern card-based task interface with animations
- **SidebarView**: Beautiful sidebar with statistics and list management
- **SyncEngine**: Google Tasks integration (in development)

## 🎨 Design System

mTask features a comprehensive design system built with SwiftUI:

### Colors
- **Primary**: Modern blue accent color
- **Status Colors**: Green for completed, orange for due today, red for overdue
- **Backgrounds**: Adaptive colors that work in light and dark modes

### Typography
- **Hierarchy**: Clear font weights and sizes from large titles to captions
- **Consistency**: Standardized text styles throughout the app

### Spacing
- **8pt Grid**: Consistent spacing system (xs: 4pt, sm: 8pt, md: 12pt, lg: 16pt, xl: 24pt, xxl: 32pt)
- **Visual Rhythm**: Harmonious spacing that creates excellent visual flow

### Components
- **Cards**: Subtle shadows and rounded corners
- **Buttons**: Multiple styles (primary, secondary, icon buttons)
- **Animations**: Smooth hover effects and state transitions

## 🛠️ Development

### Project Structure

```swift
// Example of the theme system
struct AppTheme {
    struct Colors {
        static let primary = Color.blue
        static let completedTask = Color.green.opacity(0.7)
        // ... more colors
    }
    
    struct Typography {
        static let title = Font.title2.weight(.semibold)
        // ... more typography
    }
}
```

### Adding New Features

1. **Create Views**: Add new SwiftUI views in the `Views/` folder
2. **Use Theme System**: Apply consistent styling with `AppTheme`
3. **Update Models**: Modify data models in `Models/` as needed
4. **Add Animations**: Use the animation extensions for smooth interactions

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Development Setup

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- Icons from [SF Symbols](https://developer.apple.com/sf-symbols/)
- Inspired by modern macOS design principles

## 🔮 Roadmap

- [ ] Google Tasks synchronization
- [ ] iCloud sync support
- [ ] Keyboard shortcuts customization
- [ ] Task templates
- [ ] Time tracking
- [ ] Calendar integration
- [ ] Dark mode enhancements
- [ ] Accessibility improvements

## 📞 Support

If you have any questions or run into issues, please [open an issue](https://github.com/imvipgit/mTask/issues) on GitHub.

---

<div align="center">
  Made with ❤️ using SwiftUI
</div>
