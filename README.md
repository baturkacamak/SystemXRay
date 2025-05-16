# SystemXRay 🖥️

[![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://www.linux.org/)
[![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

> A powerful system information gathering and monitoring tool for Linux systems 🔍

## 📋 Table of Contents
- [Quick Start](#-quick-start)
- [Features](#-features)
- [Requirements](#-requirements)
- [Installation](#-installation)
- [Usage](#-usage)
- [Examples](#-examples)
- [Contributing](#-contributing)
- [Support](#-support)
- [Roadmap](#-roadmap)
- [License](#-license)

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/yourusername/SystemXRay.git
cd SystemXRay

# Make scripts executable
chmod +x debian/scripts/modules/*.sh

# Run basic system scan
./debian/scripts/modules/storage_info.sh
```

## ✨ Features

### 💾 Storage Information
- 📊 Disk usage statistics
- 🔍 Detailed disk information (models, types)
- 🏥 SMART disk health monitoring
- 🌡️ Disk temperature monitoring
- 📈 Disk I/O statistics
- 📑 Basic storage device overview

### 🔑 Key Capabilities
- 📋 Detailed system analysis with `--detailed` flag
- 💿 Support for multiple storage types:
  - NVMe SSD
  - SATA SSD
  - HDD
- ⚡ Real-time disk I/O monitoring
- ✅ SMART health status reporting
- 🌡️ Temperature monitoring for storage devices

## 📋 Requirements

### System Requirements
- 🐧 Linux operating system
- 🐚 Bash shell environment
- 🔑 Root/sudo privileges for certain operations

### Required Commands
| Command | Purpose | Required |
|---------|---------|----------|
| `df` | Filesystem usage information | ✅ |
| `lsblk` | Block device information | ✅ |
| `smartctl` | SMART disk information | ❌ |
| `hddtemp` | Disk temperature monitoring | ❌ |
| `iostat` | Disk I/O statistics | ❌ |

## 🛠️ Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/SystemXRay.git
cd SystemXRay
```

2. **Make scripts executable**
```bash
chmod +x debian/scripts/modules/*.sh
```

## 💻 Usage

### Basic Usage
Get basic system information:
```bash
./debian/scripts/modules/storage_info.sh
```

### Detailed Information
Get comprehensive system information:
```bash
./debian/scripts/modules/storage_info.sh --detailed
```

## 📝 Examples

### Basic Storage Information
```bash
Storage Devices
  1. NVMe SSD: Samsung 970 EVO Plus - 1TB
  2. SATA SSD: Crucial MX500 - 500GB
```

### Detailed Information
The detailed mode provides:
- 📊 Filesystem usage
- 💿 Disk device details
- 🏥 SMART health status
- 🌡️ Disk temperatures
- 📈 I/O statistics

## 🤝 Contributing

We welcome contributions! Here's how you can help:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 💬 Support

Need help? Here's what you can do:

1. 📖 Check the [documentation](#)
2. 🔍 Search existing issues
3. 🐛 Create a new issue with:
   - System information
   - Steps to reproduce
   - Expected vs actual behavior
   - Screenshots (if applicable)

## 🗺️ Roadmap

- [ ] 🧠 CPU information gathering
- [ ] 💾 Memory usage monitoring
- [ ] 🌐 Network statistics
- [ ] 🎮 GPU information (if available)
- [ ] 🌡️ System temperature monitoring
- [ ] ⚡ Power consumption metrics

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">
Made with ❤️ by the SystemXRay Team
</div>
