import platform
import psutil
import time
import json
from datetime import datetime, timedelta
from rich.console import Console
from rich.table import Table, box
import cpuinfo
import distro
import os
import requests
import subprocess

# Path for storing network usage data
DATA_FILE = '/mnt/data/network_usage.json'

def get_initial_network_usage():
    net_io = psutil.net_io_counters()
    return {"bytes_sent": net_io.bytes_sent, "bytes_recv": net_io.bytes_recv}

def load_network_usage():
    if os.path.exists(DATA_FILE):
        with open(DATA_FILE, 'r') as file:
            return json.load(file)
    else:
        initial_data = {"daily": get_initial_network_usage(), "monthly": get_initial_network_usage()}
        save_network_usage(initial_data)
        return initial_data

def save_network_usage(data):
    os.makedirs(os.path.dirname(DATA_FILE), exist_ok=True)
    with open(DATA_FILE, 'w') as file:
        json.dump(data, file)

def calculate_bandwidth_usage(initial, current):
    bytes_sent = current['bytes_sent'] - initial['bytes_sent']
    bytes_recv = current['bytes_recv'] - initial['bytes_recv']
    total_usage = bytes_sent + bytes_recv
    return total_usage / (1024 ** 3)  # Convert to GB

def get_network_usage():
    current_usage = get_initial_network_usage()
    saved_usage = load_network_usage()
    daily_usage = calculate_bandwidth_usage(saved_usage['daily'], current_usage)
    monthly_usage = calculate_bandwidth_usage(saved_usage['monthly'], current_usage)
    return daily_usage, monthly_usage

def update_network_usage():
    current_time = datetime.now()
    current_day = current_time.day
    current_month = current_time.month

    saved_usage = load_network_usage()
    saved_time = datetime.fromtimestamp(os.path.getmtime(DATA_FILE))
    saved_day = saved_time.day
    saved_month = saved_time.month

    if current_day != saved_day:
        saved_usage['daily'] = get_initial_network_usage()
    if current_month != saved_month:
        saved_usage['monthly'] = get_initial_network_usage()
    
    save_network_usage(saved_usage)

def get_ip_info():
    try:
        response = requests.get("https://ipinfo.io")
        data = response.json()
        isp = data.get("org", "")
        if isp.startswith("AS"):
            isp = " ".join(isp.split(" ")[1:])  # Remove AS prefix
        return {
            "IP Address": data.get("ip"),
            "ISP": isp,
            "Region": data.get("region"),
            "City": data.get("city"),
            "Date": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        }
    except requests.RequestException:
        return {
            "IP Address": "N/A",
            "ISP": "N/A",
            "Region": "N/A",
            "City": "N/A",
            "Date": "N/A"
        }

def check_service_status(service_name):
    try:
        result = subprocess.run(['systemctl', 'is-active', service_name], capture_output=True, text=True)
        return result.stdout.strip()
    except Exception as e:
        return f"Error checking status: {e}"

def get_system_info():
    cpu_info = cpuinfo.get_cpu_info()
    cpu_name = cpu_info['brand_raw']
    cpu_model = platform.processor()
    cpu_cores = psutil.cpu_count(logical=True)
    cpu_physical_cores = psutil.cpu_count(logical=False)
    cpu_freq = psutil.cpu_freq()
    cpu_speed = cpu_freq.current if cpu_freq else "N/A"
    cpu_max_speed = cpu_freq.max if cpu_freq and cpu_freq.max != 0 else cpu_speed

    os_name = f"{distro.name()} {distro.version()}"
    kernel_version = platform.release()

    total_ram = psutil.virtual_memory().total / (1024 ** 3)
    used_ram = psutil.virtual_memory().used / (1024 ** 3)
    ram_percentage = psutil.virtual_memory().percent

    ram_usage_str = f"{used_ram:.2f} GB / {total_ram:.2f} GB ({ram_percentage}%)"

    uptime_seconds = time.time() - psutil.boot_time()
    uptime_str = str(timedelta(seconds=uptime_seconds)).split('.')[0]

    daily_bandwidth_usage, monthly_bandwidth_usage = get_network_usage()

    disk_usage = psutil.disk_usage('/')
    total_disk = disk_usage.total / (1024 ** 3)  # Convert to GB
    used_disk = disk_usage.used / (1024 ** 3)    # Convert to GB
    # free_disk = disk_usage.free / (1024 ** 3)    # Convert to GB
    disk_percentage = disk_usage.percent

    disk_usage_str = f"{used_disk:.2f} GB / {total_disk:.2f} GB ({disk_percentage}%)"

    nginx_status = check_service_status('nginx')
    xray_status = check_service_status('xray')

    system_data = [
        ("CPU Name", cpu_name),
        ("CPU Model", cpu_model),
        ("CPU Physical Cores", cpu_physical_cores),
        ("CPU Logical Cores", cpu_cores),
        ("CPU Current Speed (MHz)", f"{cpu_speed:.2f}" if isinstance(cpu_speed, float) else cpu_speed),
        ("CPU Max Speed (MHz)", f"{cpu_max_speed:.2f}" if isinstance(cpu_max_speed, float) else cpu_max_speed),
        ("Operating System", os_name),
        ("Kernel Version", kernel_version),
        ("RAM Usage", ram_usage_str),
        ("Disk Usage", disk_usage_str),
        ("Uptime Server", uptime_str),
        ("Nginx Status", nginx_status),
        ("Xray-core Status", xray_status)
    ]

    network_data = [
        ("Daily Bandwidth Usage (GB)", f"{daily_bandwidth_usage:.2f}"),
        ("Monthly Bandwidth Usage (GB)", f"{monthly_bandwidth_usage:.2f}")
    ]

    return system_data, network_data

def display_system_info(system_data, network_data, ip_info):
    console = Console()

    max_metric_length = max(len(item[0]) for item in system_data + network_data + list(ip_info.items()))
    max_value_length = max(len(str(item[1])) for item in system_data + network_data + list(ip_info.items()))

    system_table = Table(title="System Information", box=box.SQUARE, show_header=False, pad_edge=False, min_width=max_metric_length + max_value_length + 10)

    system_table.add_column("Metric", justify="right", style="cyan", no_wrap=True)
    system_table.add_column("Value", style="magenta")

    for item in system_data:
        if item[1]:
            system_table.add_row(item[0], str(item[1]))
        else:
            system_table.add_row(item[0], "")

    console.print(system_table)

    ip_table = Table(title="IP and Network Information", box=box.SQUARE, show_header=False, pad_edge=False, min_width=max_metric_length + max_value_length + 10)

    ip_table.add_column("Metric", justify="right", style="cyan", no_wrap=True)
    ip_table.add_column("Value", style="magenta")

    for key, value in ip_info.items():
        ip_table.add_row(key, str(value))
        if key == "City":
            for network_item in network_data:
                ip_table.add_row(network_item[0], str(network_item[1]))

    console.print(ip_table)

if __name__ == "__main__":
    update_network_usage()
    system_data, network_data = get_system_info()
    ip_info = get_ip_info()
    display_system_info(system_data, network_data, ip_info)