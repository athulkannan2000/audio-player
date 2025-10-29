# Contributing to Audio Player Remote Control

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to this project.

## 🌟 Ways to Contribute

- **Code**: Implement new features, fix bugs, improve performance
- **Hardware**: Design PCBs, create enclosure variations, optimize power consumption
- **Documentation**: Improve guides, add tutorials, translate content
- **Testing**: Report bugs, test on different platforms, write test cases
- **Design**: Create UI mockups, improve UX flows, design icons

## 🚀 Getting Started

### 1. Fork and Clone

```bash
# Fork the repository on GitHub, then clone your fork
git clone https://github.com/YOUR_USERNAME/VI_AT.git
cd VI_AT

# Add upstream remote
git remote add upstream https://github.com/ORIGINAL_OWNER/VI_AT.git
```

### 2. Create a Branch

```bash
# Create a descriptive branch name
git checkout -b feature/add-battery-monitoring
# or
git checkout -b fix/ble-connection-timeout
```

### 3. Make Changes

- Follow the code style of the existing codebase
- Write clear, descriptive commit messages
- Add comments for complex logic
- Update documentation as needed

### 4. Test Your Changes

**For ESP32 Firmware:**
- Compile without errors
- Test on actual hardware if possible
- Verify power consumption hasn't increased significantly
- Check BLE functionality with nRF Connect

**For Flutter App (when available):**
- Run `flutter analyze` (no errors)
- Run `flutter test` (all tests pass)
- Test on both iOS and Android if possible

### 5. Submit a Pull Request

```bash
# Commit your changes
git add .
git commit -m "Add battery voltage monitoring via ADC"

# Push to your fork
git push origin feature/add-battery-monitoring
```

Then open a Pull Request on GitHub with:
- Clear title describing the change
- Description of what was changed and why
- Screenshots/videos if UI-related
- Reference to related issues (e.g., "Fixes #42")

## 📋 Coding Standards

### ESP32 Firmware (C/C++)

- **Style**: Follow Arduino conventions
- **Naming**:
  - Constants: `UPPER_SNAKE_CASE`
  - Variables: `camelCase`
  - Functions: `camelCase`
- **Comments**: Use `//` for single-line, `/* */` for multi-line
- **Indentation**: 2 spaces (no tabs)

Example:
```cpp
#define MAX_RETRIES 3

bool sendCommand(const char* cmd) {
  // Implementation here
  return true;
}
```

### Flutter/Dart

- **Style**: Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- **Formatting**: Use `dart format`
- **Analysis**: Must pass `flutter analyze` with no issues
- **Naming**:
  - Classes: `PascalCase`
  - Variables/functions: `camelCase`
  - Constants: `camelCase` (with `const` or `final`)

### Documentation (Markdown)

- Use clear headings and structure
- Include code examples where helpful
- Add diagrams for complex concepts
- Keep line length reasonable (~100 chars)

## 🐛 Reporting Bugs

Use the GitHub Issues tab with the following information:

**Bug Report Template:**
```markdown
**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '...'
3. See error

**Expected behavior**
What you expected to happen.

**Screenshots/Logs**
Add screenshots or Serial Monitor output if applicable.

**Environment:**
- Hardware: ESP32-WROOM-32 / ESP32-C3
- Firmware version: v1.0.0
- Mobile OS: iOS 16 / Android 13
- App version: v1.0.0

**Additional context**
Any other relevant information.
```

## 💡 Feature Requests

Use GitHub Issues with the "enhancement" label:

**Feature Request Template:**
```markdown
**Feature Description**
Clear description of the feature.

**Use Case**
Why is this feature needed? Who would benefit?

**Proposed Implementation**
(Optional) Ideas on how to implement this.

**Alternatives Considered**
Other approaches you've thought about.
```

## 🔧 Development Setup

### ESP32 Development

**Required:**
- Arduino IDE 2.x or PlatformIO
- ESP32 board support package
- USB cable for programming

**Optional:**
- Oscilloscope for debugging
- Logic analyzer for BLE packet inspection
- Battery current meter for power profiling

### Flutter Development (Coming Soon)

**Required:**
- Flutter SDK 3.x+
- Android Studio / Xcode
- Physical device with BLE support

**Recommended:**
- VS Code with Flutter extension
- nRF Connect app for BLE testing

## 📐 Hardware Contributions

If contributing hardware designs:

1. **Schematics**: Use KiCad or Eagle (provide source files)
2. **PCB Layouts**: Include Gerber files in a `gerbers/` folder
3. **3D Models**: Provide STL files and source CAD (Fusion 360, OpenSCAD, etc.)
4. **BOM**: Include detailed Bill of Materials with part numbers
5. **Assembly Instructions**: Add clear assembly guide with photos

## 📝 Documentation Contributions

- Use clear, concise language
- Include practical examples
- Add diagrams where helpful (draw.io, Mermaid, etc.)
- Check spelling and grammar
- Update table of contents if adding new sections

## ⚡ Performance Guidelines

### ESP32 Firmware

- Minimize power consumption (target <50mA active, <10µA sleep)
- Keep memory usage low (heap fragmentation awareness)
- Avoid blocking operations in main loop
- Use deep sleep when idle

### Mobile App

- Smooth UI (60fps minimum)
- Efficient BLE polling (don't spam notifications)
- Handle background/foreground transitions gracefully
- Minimize battery drain from BLE scanning

## 🧪 Testing Requirements

Before submitting:

- [ ] Code compiles without warnings
- [ ] Existing functionality not broken (regression test)
- [ ] New features tested manually
- [ ] Power consumption checked (firmware changes)
- [ ] Documentation updated if needed
- [ ] No sensitive data (API keys, passwords) committed

## 📜 License

By contributing, you agree that your contributions will be licensed under the MIT License.

## 💬 Communication

- **GitHub Issues**: Bug reports, feature requests
- **GitHub Discussions**: Questions, ideas, general discussion
- **Pull Requests**: Code reviews and feedback

## 🙏 Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes for significant contributions
- Special mentions for major features

---

**Thank you for contributing to making audio learning more accessible!**

Questions? Open a discussion on GitHub or check existing issues.
