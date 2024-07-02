import yaml
import subprocess
import sys
import os

def load_yaml(file_path):
    try:
        with open(file_path, 'r') as file:
            return yaml.safe_load(file)
    except Exception as e:
        print(f"エラー: YAMLファイルの読み込み中にエラーが発生しました: {e}")
        sys.exit(1)

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
            name = iface['name']
            namespace = iface['namespace']
            address = iface.get('address', None)
            run_command(f"ip link set {name} netns {namespace}")
            head = f"ip netns exec {namespace}"
            if address:
                run_command(f"{head} ip addr add {address} dev {name}")
            run_command(f"{head} ip link set {name} up")

def setup_routes(routes):
    print("Setting up routes...")
    for route in routes:
        namespace = route['namespace']
        dest = route['destination']
        gway = route['gateway']
        iface = route['interface']
        run_command(f"ip netns exec {namespace} ip route add {dest} via {gway} dev {iface}")


def setup_bridges(bridges):
    print("Setting up bridges...")
    for br in bridges:
        namespace = br['namespace']
        bridge = br['name']
        head = f'ip netns exec {namespace}'

        run_command(f"{head} ip link add {bridge} type bridge")
        run_command(f"{head} ip link set {bridge} up")
        for iface in br['interfaces']:
            name = iface['name']
            run_command(f"{head} ip link set {name} master {bridge}")
            run_command(f"{head} ip link set {name} up")


def custom_commands(commands):
    print("Running custom commands...")
    for category, cmd_list in commands.items():
        print(f"Executing {category} commands:")
        for cmd in cmd_list:
            namespace = cmd['namespace']
            command = cmd['command']
            run_command(f"ip netns exec {namespace} {command}")


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
    bridges = config.get('bridges', None)
    commands = config.get('commands', None)
    tests = config.get('tests', None)

    if namespaces:
        setup_namespaces(namespaces)
    if networks:
        setup_networks(networks)
    if routes:
        setup_routes(routes)
    if bridges:
        setup_bridges(bridges)
    if commands:
        custom_commands(commands)
    if tests:
        run_tests(tests)


def main():
    # 設定ファイル名
    default_file = 'config/config.yaml'
    if len(sys.argv) > 1:
        file_name = sys.argv[1]
    else:
        file_name = default_file

    # 設定ファイルのパス
    current_dir = os.path.dirname(os.path.abspath(__file__))
    file_path = os.path.join(current_dir, file_name)

    # ファイルの存在確認
    if not os.path.exists(file_path):
        print(f"ファイル '{file_path}' が見つかりません。")
        sys.exit(1)

    data = load_yaml(file_path)
    setup(data)


if __name__ == "__main__":
    main()

