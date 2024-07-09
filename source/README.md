# Network Namespace Configuration Script

This Python script automates the creation and configuration of network namespaces using `pyroute2` based on a YAML configuration file. It provides a flexible way to set up complex network topologies for testing, learning, or hobbies.
<br>

### Features

1. The script reads a YAML configuration file
2. It creates the specified network namespaces
3. Veth pairs are set up to connect namespaces or to the host
4. Bridge interfaces are created and configured as needed
5. Static IP addresses are assigned to interfaces
6. Static routes are added to enable communication between namespaces
7. Custom commands are executed for any additional setup
<br>

### Important Notes

- **Root Privileges Required**: This script requires root privileges to create and configure network namespaces. Run it with `sudo` or as the root user.

- **Recommended for Virtual Environments**: It is recommended to run this script in a virtual machine or a containerized environment. Modifying network configurations on a production system can lead to network disruptions and unintended consequences.

### Safety Precautions

1. Always test this script in a safe, isolated environment before using it on any important systems.
2. Understand the network changes the script will make before running it.
3. Have a backup plan or recovery method in case of unexpected issues.

Remember, modifying network configurations can potentially disrupt network connectivity. Use this script responsibly and with caution.


### Usage

1. Prepare your network configuration in a YAML file
2. Run the script:
   ```
   python script_name.py [path_to_config.yaml]
   ```
   If no config file is specified, it defaults to `config/config.yaml`

### Requirements

- Python 3.x
- `pyroute2` library
- `PyYAML` library

This script provides a powerful and flexible way to create virtual network topologies using Linux network namespaces, making it ideal for network testing, development, and educational scenarios.

