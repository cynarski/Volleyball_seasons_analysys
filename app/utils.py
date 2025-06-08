from db_requests import db_requests


def get_selected_season(season_idx):
    seasons = db_requests.get_seasons()
    return seasons[season_idx] if season_idx is not None else None

def is_team_in_season(team, season):
    return team is not None and season is not None and db_requests.check_team_in_season(team, season)

def validate_team_and_season(team, season):
    if not team or season is None:
        return None
    selected_season = get_selected_season(season)
    if not is_team_in_season(team, selected_season):
        return None
    return selected_season


def format_match_result(match, set_scores, team, round):
    date = match[1]
    team_1_name = match[2]
    team_2_name = match[3]
    team_1_score = match[4]
    team_2_score = match[5]

    winner = team_1_name if team_1_score > team_2_score else team_2_name

    if team == team_1_name:
        result = f"{team_1_score}:{team_2_score}"
    else:
        result = f"{team_2_score}:{team_1_score}"


    opponent = team_1_name if team_1_name != team else team_2_name

    sets = [(set_1_score, set_2_score) for set_1_score, set_2_score in set_scores]
    return {
        "round": round,
        "result": result,
        "winner": winner == team,
        "sets": sets,
        "date": date.strftime("%d-%m-%Y %H:%M"),
        "team": opponent,
        "logo": f"/assets/teams/{opponent}.png"
    }

# def build_bracket_from_matches(top_teams, matches):
#     """
#     top_teams: lista krotek (seed, team_name, ...)
#     matches: lista krotek (team1, team2, t1_score, t2_score)
#     Zakładamy kolejność: 4 ćwierćfinały, 2 półfinały, finał, (opcjonalnie mecz o 3. miejsce)
#     """
#     def normalize(name):
#         return name.strip().lower()

#     # Rozstawienie: seed -> team_name
#     seeds = {place: name for place, name, *_ in top_teams}

#     # Klasyczna kolejność par ćwierćfinałowych (Wikipedia/FIVB):
#     qf_display_order = [
#         (1, 8),  # góra
#         (4, 5),  # góra-środek
#         (3, 6),  # dół-środek
#         (2, 7),  # dół
#     ]

#     # Dopasuj mecze do par (niezależnie od kolejności i wielkości liter)
#     qf = []
#     for idx, (seed1, seed2) in enumerate(qf_display_order):
#         found = False
#         for m in matches[:4]:
#             teams = {normalize(m[0]), normalize(m[1])}
#             if {normalize(seeds[seed1]), normalize(seeds[seed2])} == teams:
#                 qf.append(m)
#                 found = True
#                 break
#         if not found:
#             print(f"Nie znaleziono meczu ćwierćfinałowego dla pary: {seeds[seed1]} vs {seeds[seed2]}")
#     if len(qf) < 4:
#         raise ValueError(
#             f"Nie znaleziono wszystkich ćwierćfinałów! Znaleziono: {len(qf)}. Oczekiwano 4.\n"
#             f"qf: {qf}\n"
#             f"top_teams: {top_teams}\n"
#             f"matches[:4]: {matches[:4]}"
#         )

#     # Wyznacz zwycięzców ćwierćfinałów
#     qf_winners = [m[0] if m[2] > m[3] else m[1] for m in qf]

#     # Półfinały: (1vs8 winner) vs (4vs5 winner), (3vs6 winner) vs (2vs7 winner)
#     if len(qf_winners) < 4:
#         raise ValueError(f"Za mało zwycięzców ćwierćfinałów: {qf_winners}")
#     sf_pairs = [
#         (qf_winners[0], qf_winners[1]),
#         (qf_winners[2], qf_winners[3])
#     ]
#     sf = matches[4:6]
#     sf_winners = []
#     sf_losers = []
#     for i, (team1, team2, t1_score, t2_score) in enumerate(sf):
#         winner = team1 if t1_score > t2_score else team2
#         loser = team2 if t1_score > t2_score else team1
#         sf_winners.append(winner)
#         sf_losers.append(loser)

#     # Finał
#     final = matches[6]
#     final_winner = final[0] if final[2] > final[3] else final[1]
#     final_loser = final[1] if final[2] > final[3] else final[0]

#     # Mecz o 3. miejsce (jeśli jest)
#     third_place = matches[7] if len(matches) > 7 else None
#     if third_place:
#         third_winner = third_place[0] if third_place[2] > third_place[3] else third_place[1]
#         third_loser = third_place[1] if third_place[2] > third_place[3] else third_place[0]
#     else:
#         third_winner = sf_losers[0] if sf_losers[0] != final_loser else sf_losers[1]
#         third_loser = None

#     return {
#         "qf": qf,
#         "qf_winners": qf_winners,
#         "sf_pairs": sf_pairs,
#         "sf": sf,
#         "sf_winners": sf_winners,
#         "sf_losers": sf_losers,
#         "final": final,
#         "final_winner": final_winner,
#         "final_loser": final_loser,
#         "third_place": third_place,
#         "third_winner": third_winner,
#         "third_loser": third_loser,
#         "seeds": seeds,
#         "qf_display_order": qf_display_order
#     }