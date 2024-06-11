import subprocess
import json
import pandas as pd
from tabulate import tabulate

APISERVER = "127.0.0.1:10000"
XRAY = "/usr/local/bin/xray"

# ANSI escape codes
CYAN = '\033[96m'
YELLOW = '\033[93m'
GREEN = '\033[92m'
RESET = '\033[0m'

def apidata(reset=False):
    args = ["--server", APISERVER]
    if reset:
        args.append("-reset=true")
    result = subprocess.run([XRAY, "api", "statsquery"] + args, capture_output=True, text=True)
    
    try:
        data = json.loads(result.stdout)
    except json.JSONDecodeError:
        print("Failed to parse JSON")
        return []

    parsed_data = []
    if 'stat' in data:
        for item in data['stat']:
            if "name" in item and "value" in item:
                name_parts = item["name"].split(">>>")
                if len(name_parts) > 3:
                    direction = name_parts[0]
                    link = name_parts[1]
                    entity = name_parts[2]
                    type_ = name_parts[3]
                    value = item["value"]
                    parsed_data.append({"direction": direction, "link": link, "entity": entity, "type": type_, "value": int(value)})
    
    return parsed_data

def human_readable_size(size, decimal_places=1):
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if size < 1024:
            return f"{size:.{decimal_places}f} {unit}"
        size /= 1024

def print_sum(data, prefix):
    df = pd.DataFrame(data)
    df_filtered = df[df['direction'] == prefix]
    df_sorted = df_filtered.sort_values(by='value', ascending=False)

    up_sum = df_sorted[df_sorted['type'] == 'uplink']['value'].sum()
    down_sum = df_sorted[df_sorted['type'] == 'downlink']['value'].sum()
    total_sum = up_sum + down_sum

    df_sorted['value'] = df_sorted['value'].apply(human_readable_size)

    table_data = []
    for index, row in df_sorted.iterrows():
        entity = f"{row['direction']}:{row['link']}->{row['type']}"
        value = row['value']
        table_data.append([f"{YELLOW}{entity}{RESET}", f"{GREEN}{value}{RESET}"])

    summary_data = [
        [f"{YELLOW}SUM->up:{RESET}", f"{GREEN}{human_readable_size(up_sum)}{RESET}"],
        [f"{YELLOW}SUM->down:{RESET}", f"{GREEN}{human_readable_size(down_sum)}{RESET}"],
        [f"{YELLOW}SUM->TOTAL:{RESET}", f"{GREEN}{human_readable_size(total_sum)}{RESET}"]
    ]

    # Find maximum width for each column
    max_length_entity = max(len(str(row[0])) for row in table_data + summary_data)
    max_length_value = max(len(str(row[1])) for row in table_data + summary_data)

    # Create formatted table with consistent cell sizes
    formatted_table_data = [
        [f"{entity:^{max_length_entity}}", f"{value:^{max_length_value}}"] for entity, value in table_data
    ]
    formatted_summary_data = [
        [f"{entity:^{max_length_entity}}", f"{value:^{max_length_value}}"] for entity, value in summary_data
    ]

    # Combine table data and summary data for final output
    combined_data = formatted_table_data + [["", ""]] + formatted_summary_data

    # Print formatted table with a uniform grid and centered text
    table = tabulate(combined_data, headers=[f"{YELLOW}Pengguna / User{RESET}", f"{GREEN}Traffic{RESET}"], tablefmt="grid", colalign=("center", "center"))
    print(table)

if __name__ == "__main__":
    data = apidata(reset=False)
    print_sum(data, "user")