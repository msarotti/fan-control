# Fan Monitor Script

This Bash script monitors the system fan speed and provides detailed information about its activity.

## Requirements

- Linux with `lm-sensors` installed
- Root permissions or access to `sudo`

## Installation

1. Clone the repository or download the script:
   ```bash
   git clone <REPO_URL>
   cd <FOLDER_NAME>
   ```
2. Make sure the script is executable:
   ```bash
   chmod +x fan_monitor.sh
   ```
3. Install the required packages (if not already installed):
   ```bash
   sudo apt install lm-sensors  # For Debian/Ubuntu
   sudo pacman -S lm_sensors    # For Arch/Manjaro
   sudo yum install lm_sensors  # For RHEL/CentOS
   ```
4. Detect available sensors with:
   ```bash
   sudo sensors-detect
   ```

## Usage

Run the script with:
```bash
./fan_monitor.sh
```
If necessary, run it with root permissions:
```bash
sudo ./fan_monitor.sh
```

## Output

The script will display the fan speed in RPM and other relevant information about the system sensors.

## Contribute

If you want to improve the script, open an issue or submit a pull request on GitHub.

## License

This project is released under the MIT license.

