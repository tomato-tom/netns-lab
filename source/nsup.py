import yaml
from pyroute2 import IPRoute, netns, NetNS
import subprocess
import sys
import os
import time

def load_yaml():
    default_file = 'config/config.yaml'
    if len(sys.argv) > 1:
        file_name = sys.argv[1]
    else:
        file_name = default_file

    current_dir = os.path.dirname(os.path.abspath(__file__))
    file_path = os.path.join(current_dir, file_name)

    if not os.path.exists(file_path):
        print(f"File '{file_path}' not found.")
        sys.exit(1)

    try:
        with open(file_path, 'r') as file:
            return yaml.safe_load(file)
    except Exception as e:
        print(f"Error: An error occurred while reading the YAML file: {e}")
        sys.exit(1)

def create_namespace(namespaces):
    # Create network namespaces and set loopback interface up
    for name in namespaces:
        netns.create(name)
        with NetNS(name) as ns:
            lo_index = ns.link_lookup(ifname='lo')[0]
            ns.link('set', index=lo_index, state='up')

def create_veth_pair(vethpairs):
    # Create and configure veth pairs
    for veth in vethpairs:
        veth_a = veth['veth_a']['name']
        veth_b = veth['veth_b']['name']
        ns_a = veth['veth_a'].get('namespace')
        ns_b = veth['veth_b'].get('namespace')
        addr_a = veth['veth_a'].get('address')
        addr_b = veth['veth_b'].get('address')

        with IPRoute() as ip:
            # Create veth pair
            ip.link('add', ifname=veth_a, kind='veth',  peer=veth_b)
            
            # Configure veth_a
            dev_id = ip.link_lookup(ifname=veth_a)[0]
            if ns_a:   # Move to network namespace
                ip.link('set', index=dev_id, net_ns_fd=ns_a)
                with NetNS(ns_a) as ns:
                    if addr_a:
                        ns.addr('add', index=ns.link_lookup(ifname=veth_a)[0], address=addr_a)
                    ns.link('set', index=ns.link_lookup(ifname=veth_a)[0], state='up')
            else:      # Configure on host
                if addr_a:
                    ip.addr("add", index=dev_id, address=addr_a)
                ip.link("set", index=dev_id, state="up")
            
            # Configure veth_b
            dev_id = ip.link_lookup(ifname=veth_b)[0]
            if ns_b:   # Move to network namespace
                ip.link('set', index=dev_id, net_ns_fd=ns_b)
                with NetNS(ns_b) as ns:
                    if addr_b:
                        ns.addr('add', index=ns.link_lookup(ifname=veth_b)[0], address=addr_b)
                    ns.link('set', index=ns.link_lookup(ifname=veth_b)[0], state='up')
            else:      # Configure on host
                if addr_b:
                    ip.addr("add", index=dev_id, address=addr_b)
                ip.link("set", index=dev_id, state="up")

def create_bridge(bridges):
    # Create bridges and add ports
    for br in bridges:
        namespace = br['namespace']
        bridge_name = br['name']
        ports = br['ports']

        with NetNS(namespace) as ns:
            # Create bridge
            ns.link('add', ifname=bridge_name, kind='bridge')
            ns.link('set', ifname=bridge_name, state='up')

            # Add ports to bridge
            for port in ports:
                port_name = port['name']
                bridge_index = ns.link_lookup(ifname=bridge_name)[0]
                port_index = ns.link_lookup(ifname=port_name)[0]
                ns.link('set', index=port_index, master=bridge_index)
                ns.link('set', index=port_index, state='up')

def add_route(routes):
    # Add routes to network namespaces
    for route in routes:
        namespace = route['namespace']
        destination = route['destination']
        via = route['via']
        interface = route['interface']
        
        with NetNS(namespace) as ns:
            if destination == 'default':
                ns.route('add', gateway=via, oif=ns.link_lookup(ifname=interface)[0])
            else:
                ns.route('add', dst=destination, gateway=via, oif=ns.link_lookup(ifname=interface)[0])

def run_command(commands):
    # Run custom commands
    for cmd in commands:
        if 'namespace' in cmd:
            command = f"ip netns exec {cmd['namespace']} {cmd['command']}"
        else:
            command = cmd['command']
        try:
            subprocess.run(command, shell=True, check=True)
        except subprocess.CalledProcessError as e:
            print(f"Error executing command: {command}")
            print(f"Error message: {e}")
            sys.exit(1)

def main():
    config = load_yaml()

    # Create namespaces
    create_namespace(config['namespaces'])

    # Create and configure veth pairs
    vethpairs = config.get('vethpairs')
    if vethpairs:
        create_veth_pair(vethpairs)

    # Create bridge and add ports
    bridges = config.get('bridges')
    if bridges:
        create_bridge(bridges)

    # Configure routing
    routes = config.get('routes')
    if routes:
        add_route(routes)

    # Run custom commands
    commands = config.get('commands')
    if commands:
        run_command(commands)

if __name__ == "__main__":
    main()

