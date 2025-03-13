import requests
from bs4 import BeautifulSoup
import csv


URL = "https://pl.wikipedia.org/wiki/PlusLiga_(2016/2017)"
CSV_FILE = "data/match_data_2016_17.csv"


try:
    response = requests.get(URL, timeout=10)
    response.raise_for_status()
except requests.RequestException as e:
    print(f"Error: {e}")
    exit()


soup = BeautifulSoup(response.content, "html.parser")


tables = soup.find_all('table', {'class': 'wikitable'})
if not tables or len(tables) < 5:
    print("No matching table found on the page.")
    exit()

table = tables[2]

data = []
for row in table.find_all('tr')[1:]:
    cols = row.find_all('td')


    if len(cols) < 7:
        continue

    match_info = {
        "Date": cols[0].text.strip(),
        "Time": cols[1].text.strip(),
        "Host": cols[2].text.strip(),
        "Result": cols[3].text.strip(),
        "Guest": cols[4].text.strip(),
        "Audience": cols[5].text.strip(),
        "MVP": cols[6].text.strip()
    }

    data.append(match_info)

try:
    with open(CSV_FILE, mode="w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=data[0].keys())
        writer.writeheader()
        writer.writerows(data)

    print(f"Data loaded to  '{CSV_FILE}'")
except Exception as e:
    print(f"Error{e}")
