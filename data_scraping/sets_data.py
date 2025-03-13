import psycopg2
import pandas as pd
import re

teams = {
    "LUK Lublin": "LUK  Lublin",
    "Indykpol AZS Olsztyn": "AZS Olsztyn",
    "Grupa Azoty ZAKSA Kędzierzyn-Koźle": "ZAKSA Kędzierzyn-Koźle",
    "Aluron CMC Warta Zawiercie": "Warta Zawiercie",
    "PSG Stal Nysa": "Stal Nysa",
    "Cerrad Enea Czarni Radom": "Czarni Radom",
    "Projekt Warszawa": "Projekt Warszawa",
    "Asseco Resovia Rzeszów": "Asseco Resovia",
    "Verva Warszawa Orlen Paliwa": "Projekt Warszawa",
    "Aluron Virtu CMC Zawiercie": "Warta Zawiercie",
    "Aluron Virtu Warta Zawiercie": "Warta Zawiercie",
    "Onico Warszawa": "Projekt Warszawa",
    "Dafi Społem Kielce": "Społem Kielce",
    "Espadon Szczecin": "Stocznia Szczecin",
    "Łuczniczka Bydgoszcz": "Chemik Bydgoszcz",
    "Effector Kielce": "Społem Kielce",
}

DB_CONFIG = {
    "user": "user",
    "password": "password",
    "database": "volleyball_app",
    "host": "localhost",
    "port": 1234,
}

file_path = "data/match_data_2016_17.csv"
df = pd.read_csv(file_path)

df["Date"] = pd.to_datetime(df["Date"], errors="coerce", dayfirst=True)

df["Time"] = df["Time"].fillna("00:00")

df["Date"] = df["Date"].dt.strftime("%Y-%m-%d") + " " + df["Time"]

df["Date"] = pd.to_datetime(df["Date"], format="%Y-%m-%d %H:%M", errors="coerce")

df["Season"] = df["Date"].apply(lambda x: f"{x.year - 1}/{x.year}" if x.month < 7 else f"{x.year}/{x.year + 1}")

try:
    conn = psycopg2.connect(**DB_CONFIG)
    cursor = conn.cursor()
    print("Connected to database")
except Exception as e:
    exit()

cursor.execute("SELECT id, season FROM Season")
seasons_dict = {row[1]: row[0] for row in cursor.fetchall()}

cursor.execute("SELECT id, TeamName FROM Team")
teams_dict = {team_name: team_id for team_id, team_name in cursor.fetchall()}

def parse_sets(result):
    match = re.search(r"\((.*?)\)", str(result))
    if match:
        sets = match.group(1).split(", ")
        return [tuple(map(int, s.split(":"))) for s in sets]
    return []

for index, row in df.iterrows():
    if pd.isna(row["Host"]) or pd.isna(row["Guest"]) or pd.isna(row["Result"]):
        continue

    host_team = teams.get(row["Host"], row["Host"])
    guest_team = teams.get(row["Guest"], row["Guest"])

    host_id = teams_dict.get(host_team)
    guest_id = teams_dict.get(guest_team)

    if not host_id or not guest_id:
        continue

    season_id = seasons_dict.get(row["Season"])
    if not season_id:
        print(f"No season {row['Season']}")
        continue

    cursor.execute("""
        SELECT id FROM Matches
        WHERE date = %s;
    """, (row["Date"],))

    match = cursor.fetchone()
    if not match:
        print(f"No match {host_team} vs {guest_team} ({row['Date']}) in database")
        continue

    match_id = match[0]

    cursor.execute("""
        INSERT INTO Matches_extended (match_id, audience, mvp)
        VALUES (%s, %s, %s)
        ON CONFLICT (match_id) DO UPDATE 
        SET audience = EXCLUDED.audience, mvp = EXCLUDED.mvp;
    """, (match_id, row["Audience"], row["MVP"]))

    cursor.execute("DELETE FROM Set_scores WHERE match_id = %s", (match_id,))

    set_scores = parse_sets(row["Result"])
    for set_number, (host_score, guest_score) in enumerate(set_scores, start=1):
        cursor.execute("""
            INSERT INTO Set_scores (match_id, set_number, host_score, guest_score)
            VALUES (%s, %s, %s, %s)
        """, (match_id, set_number, host_score, guest_score))

conn.commit()
cursor.close()
conn.close()
print("✅ Data loaded")