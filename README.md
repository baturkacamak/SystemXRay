# SystemXRay 🖥️

[![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://www.linux.org/)
[![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

> A powerful system information gathering and monitoring tool for Linux systems 🔍

## 📋 Table of Contents
- [Quick Start](#-quick-start)
- [Features](#-features)
- [Command Line Parameters](#-command-line-parameters)
- [Configuration](#-configuration)
- [Requirements](#-requirements)
- [Installation](#-installation)
- [Usage](#-usage)
- [Examples](#-examples)
- [Troubleshooting](#-troubleshooting)
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
  - Filesystem usage with `df`
  - Excludes tmpfs and udev filesystems
  - Human-readable sizes
- 🔍 Detailed disk information
  - Device models and types
  - Mount points
  - Filesystem types
  - Device sizes
- 🏥 SMART disk health monitoring
  - Model family information
  - Device model details
  - Serial numbers
  - Firmware versions
  - User capacity
  - Overall health status
- 🌡️ Disk temperature monitoring
  - Real-time temperature readings
  - Support for all SATA devices
- 📈 Disk I/O statistics
  - Extended I/O statistics
  - Real-time monitoring
  - Detailed performance metrics
- 📑 Basic storage device overview
  - Device enumeration
  - Vendor information
  - Model details
  - Size information
  - Storage type detection

### 🧠 CPU Information
- 📊 Basic CPU Information
  - CPU model name
  - Number of cores
  - Number of threads
  - Total thread count
- 🔍 Detailed CPU Information
  - CPU features
  - Maximum frequency
  - L3 cache details
  - Temperature monitoring
  - CPU usage statistics
- 🏗️ CPU Architecture
  - Architecture type
  - CPU operation modes
  - Byte order
  - Vendor ID
  - Virtualization support
  - Hypervisor details
- 🚩 CPU Features and Flags
  - Complete list of CPU flags
  - Supported instruction sets
  - Advanced features

### 💾 Memory Information
- 📊 Basic RAM Information
  - Total memory size
  - Memory module details
- 🔍 Detailed Memory Information
  - Memory usage statistics
  - Detailed module information
    - Module size
    - Memory type
    - Operating speed
    - Manufacturer
    - Serial number
    - Part number
- 💿 Swap Information
  - Swap usage statistics
  - Swap areas
  - Swap device details
- 📈 Memory Usage Details
  - Top memory-consuming processes
  - Process memory statistics

### 🎮 GPU Information
- 📊 Basic GPU Information
  - GPU model
  - Driver version
  - Memory size
- 🔍 Detailed GPU Information
  - GPU architecture
  - Compute capabilities
  - Temperature monitoring
  - Power usage
  - Performance statistics
- 🎯 GPU Features
  - Supported APIs
  - Display outputs
  - Video capabilities

### 🌐 Network Information
- 📊 Basic Network Information
  - Network interfaces
  - IP addresses
  - Connection status
- 🔍 Detailed Network Information
  - Network statistics
  - Connection details
  - Routing information
- 📈 Network Performance
  - Bandwidth usage
  - Connection speed
  - Latency statistics

### 📦 Package Management
- 📊 Package Information
  - Installed packages
  - Package versions
  - Dependencies
- 🔍 System Updates
  - Available updates
  - Security patches
  - System upgrades
- 📈 Package Statistics
  - Package sizes
  - Installation dates
  - Update history

### 🔑 Key Capabilities
- 📋 Detailed system analysis with `--detailed` flag
- 💿 Support for multiple storage types:
  - NVMe SSD
  - SATA SSD
  - HDD
- ⚡ Real-time monitoring
- ✅ Health status reporting
- 🌡️ Temperature monitoring
- 📊 Performance statistics

## 🎮 Command Line Parameters

### Global Parameters
| Parameter | Short | Description | Example |
|-----------|-------|-------------|---------|
| `--help` | `-h` | Display help information | `./hardware-report.sh --help` |
| `--output` | `-o` | Save output to file | `./hardware-report.sh --output report.txt` |
| `--html` | `-H` | Generate HTML report | `./hardware-report.sh --html` |
| `--interactive` | `-i` | Run in interactive mode | `./hardware-report.sh --interactive` |
| `--sections` | `-s` | Specify sections to display | `./hardware-report.sh --sections cpu,memory` |
| `--language` | `-l` | Set output language | `./hardware-report.sh --language en` |
| `--detailed` | `-d` | Show detailed information | `./hardware-report.sh --detailed` |

### Module-Specific Parameters

#### Storage Information
| Parameter | Description | Example |
|-----------|-------------|---------|
| `--smart` | Show SMART information | `./storage_info.sh --smart` |
| `--temp` | Show temperature information | `./storage_info.sh --temp` |
| `--io` | Show I/O statistics | `./storage_info.sh --io` |

#### CPU Information
| Parameter | Description | Example |
|-----------|-------------|---------|
| `--temp` | Show temperature information | `./cpu_info.sh --temp` |
| `--usage` | Show CPU usage | `./cpu_info.sh --usage` |
| `--arch` | Show architecture details | `./cpu_info.sh --arch` |

#### Memory Information
| Parameter | Description | Example |
|-----------|-------------|---------|
| `--swap` | Show swap information | `./memory_info.sh --swap` |
| `--modules` | Show memory modules | `./memory_info.sh --modules` |
| `--processes` | Show memory processes | `./memory_info.sh --processes` |

#### GPU Information
| Parameter | Description | Example |
|-----------|-------------|---------|
| `--nvidia` | Show NVIDIA GPU info | `./gpu_info.sh --nvidia` |
| `--amd` | Show AMD GPU info | `./gpu_info.sh --amd` |
| `--displays` | Show display information | `./gpu_info.sh --displays` |

#### Network Information
| Parameter | Description | Example |
|-----------|-------------|---------|
| `--interfaces` | Show network interfaces | `./network_info.sh --interfaces` |
| `--stats` | Show network statistics | `./network_info.sh --stats` |
| `--connections` | Show active connections | `./network_info.sh --connections` |

#### Package Management
| Parameter | Description | Example |
|-----------|-------------|---------|
| `--updates` | Show available updates | `./package_manager.sh --updates` |
| `--security` | Show security updates | `./package_manager.sh --security` |
| `--stats` | Show package statistics | `./package_manager.sh --stats` |

## ⚙️ Configuration

### Configuration Files
The tool uses several configuration files located in the `debian/scripts/config` directory:

1. **colors.sh**
   - Defines color schemes for output
   - Customize output appearance
   ```bash
   # Example color configuration
   RED='\033[0;31m'
   GREEN='\033[0;32m'
   YELLOW='\033[1;33m'
   ```

2. **language.sh**
   - Defines language strings
   - Supports multiple languages
   ```bash
   # Example language configuration
   CPU_INFO="CPU Information"
   MEMORY_INFO="Memory Information"
   ```

3. **settings.sh**
   - Global settings
   - Default values
   ```bash
   # Example settings
   DETAILED=false
   INTERACTIVE=false
   OUTPUT_FORMAT="text"
   ```

### Customizing Output

1. **Text Output**
   ```bash
   ./hardware-report.sh --output report.txt
   ```

2. **HTML Output**
   ```bash
   ./hardware-report.sh --html --output report.html
   ```

3. **Interactive Mode**
   ```bash
   ./hardware-report.sh --interactive
   ```

4. **Selective Sections**
   ```bash
   ./hardware-report.sh --sections cpu,memory,gpu
   ```

### Language Support

1. **Change Language**
   ```bash
   ./hardware-report.sh --language en  # English
   ./hardware-report.sh --language es  # Spanish
   ./hardware-report.sh --language fr  # French
   ```

2. **Add New Language**
   ```bash
   # Create new language file in debian/scripts/config/languages/
   cp debian/scripts/config/languages/en.sh debian/scripts/config/languages/your_language.sh
   # Edit the new language file
   ```

## 📋 Requirements

### System Requirements
- 🐧 Linux operating system
- 🐚 Bash shell environment
- 🔑 Root/sudo privileges for certain operations

### Required Commands
| Command | Purpose | Required | Package Name |
|---------|---------|----------|--------------|
| `df` | Filesystem usage information | ✅ | coreutils |
| `lsblk` | Block device information | ✅ | util-linux |
| `smartctl` | SMART disk information | ❌ | smartmontools |
| `hddtemp` | Disk temperature monitoring | ❌ | hddtemp |
| `iostat` | Disk I/O statistics | ❌ | sysstat |
| `lscpu` | CPU information | ✅ | util-linux |
| `sensors` | Temperature monitoring | ❌ | lm-sensors |
| `free` | Memory information | ✅ | procps |
| `dmidecode` | Hardware information | ❌ | dmidecode |
| `nvidia-smi` | GPU information | ❌ | nvidia-utils |
| `ip` | Network information | ✅ | iproute2 |
| `apt`/`dnf`/`pacman` | Package management | ✅ | package manager |

### Package Installation
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install coreutils util-linux smartmontools hddtemp sysstat lm-sensors procps dmidecode nvidia-utils iproute2

# Fedora
sudo dnf install coreutils util-linux smartmontools hddtemp sysstat lm-sensors procps dmidecode nvidia-utils iproute2

# Arch Linux
sudo pacman -S coreutils util-linux smartmontools hddtemp sysstat lm-sensors procps dmidecode nvidia-utils iproute2
```

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

3. **Install dependencies**
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install coreutils util-linux smartmontools hddtemp sysstat lm-sensors procps dmidecode nvidia-utils iproute2
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

### Help Information
Display help and usage information:
```bash
./debian/scripts/modules/storage_info.sh --help
```

### Module-Specific Usage

#### Storage Information
```bash
# Basic storage information
./debian/scripts/modules/storage_info.sh

# Detailed storage information
./debian/scripts/modules/storage_info.sh --detailed
```

#### CPU Information
```bash
# Basic CPU information
./debian/scripts/modules/cpu_info.sh

# Detailed CPU information
./debian/scripts/modules/cpu_info.sh --detailed
```

#### Memory Information
```bash
# Basic memory information
./debian/scripts/modules/memory_info.sh

# Detailed memory information
./debian/scripts/modules/memory_info.sh --detailed
```

#### GPU Information
```bash
# Basic GPU information
./debian/scripts/modules/gpu_info.sh

# Detailed GPU information
./debian/scripts/modules/gpu_info.sh --detailed
```

#### Network Information
```bash
# Basic network information
./debian/scripts/modules/network_info.sh

# Detailed network information
./debian/scripts/modules/network_info.sh --detailed
```

#### Package Management
```bash
# Basic package information
./debian/scripts/modules/package_manager.sh

# Detailed package information
./debian/scripts/modules/package_manager.sh --detailed
```

## 📝 Examples

### Storage Information Example
```bash
=== Disk Usage ===
Filesystem      Size  Used Avail Use% Mounted on
/dev/nvme0n1p2  916G  523G  347G  61% /

=== Disk Information ===
NAME        SIZE TYPE MOUNTPOINT FSTYPE
nvme0n1     1.0T disk
├─nvme0n1p1  512M part /boot/efi vfat
└─nvme0n1p2  916G part /         ext4

=== SMART Information ===
Device: /dev/nvme0n1
Model Family:     Samsung NVMe SSD
Device Model:     Samsung SSD 970 EVO Plus 1TB
Serial Number:    S4P8NF0M123456
Firmware Version: 2B2QEXM7
User Capacity:    1,000,204,886,016 bytes

=== Disk Temperatures ===
/dev/sda: Samsung SSD 860 EVO 500GB: 35°C
/dev/sdb: WDC WD20EZRZ-00Z5HB0: 38°C

=== Disk I/O Statistics ===
Device            r/s     w/s     rkB/s     wkB/s   rrqm/s   wrqm/s  %rrqm  %wrqm r_await w_await aqu-sz rareq-sz wareq-sz  svctm  %util
nvme0n1          0.00    0.00      0.00      0.00     0.00     0.00   0.00   0.00    0.00    0.00   0.00     0.00     0.00   0.00   0.00
```

### CPU Information Example
```bash
=== CPU Information ===
Model name:      Intel(R) Core(TM) i7-9700K CPU @ 3.60GHz
CPU(s):          8
Thread(s) per core: 1
CPU max MHz:     4900.0000
L3 cache:        12288K

=== CPU Temperature ===
Core 0:         +45.0°C
Core 1:         +44.0°C
Core 2:         +46.0°C
Core 3:         +45.0°C
Package id 0:   +47.0°C

=== CPU Usage ===
CPU Usage: 12.5%

=== CPU Architecture ===
Architecture:        x86_64
CPU op-mode(s):      32-bit, 64-bit
Byte Order:          Little Endian
Vendor ID:           GenuineIntel
Virtualization:      VT-x
Hypervisor vendor:   KVM
```

### Memory Information Example
```bash
=== Memory Information ===
              total        used        free      shared  buff/cache   available
Mem:           15Gi       4.2Gi       8.1Gi       306Mi       3.2Gi        11Gi
Swap:         2.0Gi       0.0Gi       2.0Gi

=== Memory Modules ===
RAM 1: 8GB, DDR4, 3200MHz, Crucial, CT8G4DFD832A
RAM 2: 8GB, DDR4, 3200MHz, Crucial, CT8G4DFD832A

=== Top Memory Processes ===
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
user      1234  2.5  5.2 1234567 890123 ?     Sl   10:00   0:30 /usr/bin/firefox
user      1235  1.8  3.1  987654 456789 ?     Sl   10:01   0:15 /usr/bin/chrome
```

### GPU Information Example
```bash
=== GPU Information ===
Model: NVIDIA GeForce RTX 3080
Driver Version: 470.82.01
Memory: 10GB GDDR6X

=== GPU Details ===
Architecture: Ampere
Compute Capability: 8.6
Temperature: 65°C
Power Usage: 220W
Performance State: P0

=== GPU Features ===
CUDA Version: 11.4
OpenGL Version: 4.6
Vulkan Version: 1.2
Display Outputs: 3
```

### Network Information Example
```bash
=== Network Interfaces ===
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 00:11:22:33:44:55 brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.100/24 brd 192.168.1.255 scope global dynamic eth0

=== Network Statistics ===
Interface: eth0
    RX bytes: 1.2GB
    TX bytes: 500MB
    RX packets: 1000000
    TX packets: 500000
    RX errors: 0
    TX errors: 0
```

### Package Management Example
```bash
=== Package Information ===
Total Packages: 1234
Upgradable: 15
Security Updates: 3

=== Available Updates ===
linux-image-generic (5.4.0-100.113)
firefox (100.0+build1-0ubuntu0.20.04.1)
openssl (1.1.1f-1ubuntu2.16)

=== Package Statistics ===
Total Size: 4.5GB
Last Update: 2024-02-20
Update History: 150 updates in last 30 days
```

## 🔧 Troubleshooting

### Common Issues and Solutions

#### Storage Information
1. **SMART Information Not Available**
   - Solution: Install smartmontools
   ```bash
   sudo apt-get install smartmontools
   ```

2. **Temperature Monitoring Not Working**
   - Solution: Install hddtemp and start the service
   ```bash
   sudo apt-get install hddtemp
   sudo systemctl start hddtemp
   ```

#### CPU Information
1. **Temperature Monitoring Not Working**
   - Solution: Install and configure lm-sensors
   ```bash
   sudo apt-get install lm-sensors
   sudo sensors-detect
   ```

2. **CPU Usage Statistics Not Available**
   - Solution: Install sysstat
   ```bash
   sudo apt-get install sysstat
   ```

#### Memory Information
1. **Detailed Memory Information Not Available**
   - Solution: Install dmidecode
   ```bash
   sudo apt-get install dmidecode
   ```

2. **Memory Module Information Incomplete**
   - Solution: Run with sudo privileges
   ```bash
   sudo ./debian/scripts/modules/memory_info.sh
   ```

#### GPU Information
1. **NVIDIA GPU Information Not Available**
   - Solution: Install NVIDIA drivers and nvidia-utils
   ```bash
   sudo apt-get install nvidia-driver-470 nvidia-utils-470
   ```

2. **AMD GPU Information Not Available**
   - Solution: Install AMD drivers
   ```bash
   sudo apt-get install amdgpu-install
   ```

#### Network Information
1. **Network Statistics Not Available**
   - Solution: Install iproute2
   ```bash
   sudo apt-get install iproute2
   ```

2. **Detailed Network Information Incomplete**
   - Solution: Run with sudo privileges
   ```bash
   sudo ./debian/scripts/modules/network_info.sh
   ```

#### Package Management
1. **Package Information Not Available**
   - Solution: Update package lists
   ```bash
   sudo apt-get update
   ```

2. **Update Information Not Available**
   - Solution: Check package manager configuration
   ```bash
   sudo dpkg-reconfigure apt
   ```

### General Troubleshooting

1. **Permission Denied**
   - Solution: Run with sudo privileges
   ```bash
   sudo ./debian/scripts/modules/*.sh
   ```

2. **Command Not Found**
   - Solution: Install required packages
   ```bash
   sudo apt-get install coreutils util-linux smartmontools hddtemp sysstat lm-sensors procps dmidecode nvidia-utils iproute2
   ```

3. **Script Not Executable**
   - Solution: Make scripts executable
   ```bash
   chmod +x debian/scripts/modules/*.sh
   ```

4. **Output Format Issues**
   - Solution: Check terminal encoding
   ```bash
   export LANG=en_US.UTF-8
   ```

### Advanced Troubleshooting

#### Performance Issues
1. **High CPU Usage**
   - Solution: Adjust monitoring intervals
   ```bash
   # Edit settings.sh
   MONITOR_INTERVAL=5  # Increase interval
   ```

2. **Memory Leaks**
   - Solution: Check for background processes
   ```bash
   ps aux | grep systemxray
   ```

#### Output Issues
1. **HTML Report Generation Fails**
   - Solution: Check template files
   ```bash
   ls -l debian/scripts/templates/
   ```

2. **Color Output Issues**
   - Solution: Check terminal support
   ```bash
   echo $TERM
   ```

#### Module-Specific Issues

[Previous module-specific troubleshooting remains unchanged...]

### Debug Mode
Enable debug mode for detailed troubleshooting:
```bash
export SYSTEMXRAY_DEBUG=1
./hardware-report.sh
```

### Log Files
Check log files for detailed error information:
```bash
tail -f /var/log/systemxray.log
```

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
