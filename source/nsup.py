import yaml
import subprocess
import sys

def run_command(command):
    try:
        subprocess.run(command, shell=True, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {command}")
        print(f"Error message: {e}")
        sys.exit(1)

def setup_namespaces(namespaces):
    print("Setting up namespaces...")
    for ns in namespaces:
        run_command(f"ip netns add {ns['name']}")
        run_command(f"ip netns exec {ns['name']} ip link set lo up")

def setup_networks(networks):
    print("Setting up networks...")
    for net_name, net_config in networks.items():
        ifaces = net_config['interfaces']
        run_command(f"ip link add {ifaces[0]['name']} type veth peer name {ifaces[1]['name']}")
        
        for iface in ifaces:
            run_command(f"ip link set {iface['name']} netns {iface['namespace']}")
            run_command(f"ip netns exec {iface['namespace']} ip addr add {iface['address']} dev {iface['name']}")
            run_command(f"ip netns exec {iface['namespace']} ip link set {iface['name']} up")

def setup_routes(routes):
    print("Setting up routes...")
    for route in routes:
        run_command(f"ip netns exec {route['namespace']} ip route add {route['destination']} via {route['gateway']} dev {route['interface']}")

def run_tests(tests):
    print("Running tests...")
    for test in tests:
        if test['type'] == 'ping':
            print(f"Pinging from {test['from']} to {test['to']}")
            run_command(f"ip netns exec {test['from']} ping -c {test['count']} {test['to']}")

def setup(config):
    namespaces = config.get('namespaces', None)
    networks = config.get('networks', None)
    routes = config.get('routes', None)
    tests = config.get('tests', None)

    if namespaces:
        setup_namespaces(namespaces)
    if networks:
        setup_networks(networks)
    if routes:
        setup_routes(routes)
    if tests:
        run_tests(tests)


def main():
    try:
        with open('config.yaml', 'r') as file:
            config = yaml.safe_load(file)
    except FileNotFoundError:
        print("Error: network_config.yaml not found.")
        sys.exit(1)
    except yaml.YAMLError as e:
        print(f"Error parsing YAML file: {e}")
        sys.exit(1)

    setup(config)


if __name__ == "__main__":
    main()
