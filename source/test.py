from pyroute2 import netns
from netnsup import load_yaml
from netnsup import create_namespace
from netnsup import create_veth_pair
from netnsup import create_bridges
from netnsup import add_route
from netnsup import run_command


config = load_yaml()

create_namespace(config['namespaces'])

# Create and configure veth pairs
vethpairs = config.get('vethpairs')
if vethpairs:
    create_veth_pair(config['vethpairs'])

# Configure routing
routes = config.get('routes')
if routes:
    add_route(config['routes'])

# Configure bridges
bridges = config.get('bridges')
if routes:
    create_bridge(config['bridges'])

# Run custom commands
commands = config.get('commands')
if commands:
    run_command(commands)

# remove netns
for name in netns.listnetns():
    print(f'delate {name}')
    netns.remove(name)

