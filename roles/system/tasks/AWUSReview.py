import re

# Input and output files
input_file = "AWUS036ACH_wifi_adapter.yml"   # Change this to your actual file name
output_file = "tasks.md"

task_names = []

# Read the YAML and extract lines that begin with `- name:`
with open(input_file, "r") as f:
    for line in f:
        match = re.match(r"^\s*-\s*name:\s*(.+)", line)
        if match:
            task_names.append(match.group(1).strip())

# Write to markdown file
with open(output_file, "w") as f:
    for name in task_names:
        f.write(f"- {name}\n")

print(f"Extracted {len(task_names)} task name(s) to {output_file}")
