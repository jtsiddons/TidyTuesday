#! /bin/env python

import random
import os
import datetime
import re
import requests
import pandas as pd

cwd = os.getcwd()
if cwd.split("/")[-1] != "TidyTuesday":
    print("[!] Please run this in the TidyTuesday directory. Exiting.")
    exit()

os.chdir("/home/joe/Documents/TidyTuesday")

# Constants
TIDYVERSE_URL: str = (
    "https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/"
)
TIDYVERSE_DATA_URL: str = (
    "https://github.com/rfordatascience/tidytuesday/tree/master/data/"
)


# Get week's Tuesday
# --------------------
today = datetime.date.today()
current_weekday = today.weekday()

if current_weekday == 1:
    tues = today
elif current_weekday < 1:
    tues = today - datetime.timedelta(6)
else:
    tues = today - datetime.timedelta(current_weekday - 1)

year = tues.year
date_str = tues.isoformat()

for file in os.listdir():
    if not os.path.isdir(file):
        continue
    if date_str in file:
        print(f"[!] It appears project already exists this week! ({file}) - Exiting")
        exit()

# Get current week project name
# --------------------

## Get the README, parse, and format into lines
readme = requests.get(TIDYVERSE_URL + "README.md").content.decode().split("\n")

# Extract the project line from the data table
week_line = [
    line for line in readme if re.search(r"\| [0-9]* \| `%s`" % date_str, line)
][0]
week = int(week_line[2:4])
project, source, article = re.findall(r"\[([^\|]*)\]\(([^\|]*)\)", week_line)

dir_name = date_str + "_" + project[0].replace(" ", "")
week_readme = requests.get(TIDYVERSE_URL + project[1] + "/readme.md").content.decode()

# Get all CSV files for this week
# --------------------

## Start with the data csv - to extract this weeks files
data_names = "https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/static/tt_data_type.csv"
all_csvs = requests.get(data_names).content.decode().split("\n")
this_week_csv = [
    line.split(",")[3] for line in all_csvs if re.search(r",%s," % date_str, line)
]

# Creating the project directory
# --------------------

print(f"[i] Building project {dir_name}")
## Make main dir
if not os.path.exists(dir_name):
    os.mkdir(dir_name)
os.chdir(dir_name)

## Make sub_dirs
for d in ["data", "code", "figs"]:
    if not os.path.exists(d):
        os.mkdir(d)

## Download all data.
os.chdir("data")

for csv in this_week_csv:
    if not os.path.exists(csv):
        print("[i] downloading: " + TIDYVERSE_URL + project[1] + "/" + csv)
        current_data = requests.get(TIDYVERSE_URL + project[1] + "/" + csv)
        with open(csv, "w") as io:
            io.write(current_data.content.decode())

os.chdir("..")

print("-" * 25)

print("[i] Initialising README")

lang_choice = random.randrange(3)
lang = ["Julia", "R", "Python"]

print(f"[i] Working in {lang[lang_choice]} this week!")

## Initialise README
if not os.path.exists("README.md"):
    with open("README.md", "w") as io:
        io.write(f"# {date_str}: {project[0]}\n\n")
        io.write(f"Week f{week}. This week I am working in {lang[lang_choice]}.\n\n")
        io.write("## Data\n\n")
        io.write(f"Data from [{source[0]}]({source[1]})\n")
        io.write(f"More information can be found at [{article[0]}]({article[1]})")
        io.write("\n\n### Tables\n\n")
        for csv in this_week_csv:
            df = pd.read_csv("data/" + csv)
            io.write(f"#### {csv}\n\n##### Data Type\n\n")
            io.write(df.dtypes.to_markdown())
            io.write("\n\n##### Data Summary\n\n")
            io.write(df.describe().T.to_markdown())
            io.write("\n\n")

print("-" * 25)

# Initialise Script
os.chdir("code")
possibilites = ["eda.jl", "eda.r", "eda.py"]
code_exists = False
for (i, poss) in enumerate(possibilites):
    if os.path.exists(poss):
        code_exists = True
        break

if not code_exists:
    script_file = possibilites[lang_choice]
    print(f"[i] Initialising Code - file is {script_file}")
    if script_file == "eda.jl":
        with open(script_file, "w") as io:
            io.write("using CSV\nusing DataFrames\nusing CairoMakie\n\n\n")
            for csv in this_week_csv:
                file_prefix = csv.split(".")[0]
                io.write(f'{file_prefix}_file = "./data/{csv}"\n')
                io.write(
                    f"{file_prefix}_df = DataFrame(CSV.File({file_prefix}_file, stringtype=String));\n\n"
                )
    elif script_file == "eda.r":
        with open(script_file, "w") as io:
            io.write("library(tidyverse)\n\n\n")
            for csv in this_week_csv:
                file_prefix = csv.split(".")[0]
                io.write(f'{file_prefix}_file -> "./data/{csv}"\n')
                io.write(f"{file_prefix}_df -> read.csv({file_prefix}_file)\n\n")
    else:
        with open(script_file, "w") as io:
            io.write("import pandas as pd\nimport seaborn as sns\n\n\n")
            for csv in this_week_csv:
                file_prefix = csv.split(".")[0]
                io.write(f'{file_prefix}_file = "./data/{csv}"\n')
                io.write(f"{file_prefix}_df = pd.read_csv({file_prefix}_file)\n\n")

print("-" * 25)

print("[i] Script Complete!")

os.chdir(cwd + dir_name)
