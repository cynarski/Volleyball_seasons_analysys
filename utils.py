def format_match_result(match, set_scores, team, round):
    date = match[1]
    team_1_name = match[2]
    team_2_name = match[3]
    team_1_score = match[4]
    team_2_score = match[5]

    # Określenie, która drużyna wygrała
    winner = team_1_name if team_1_score > team_2_score else team_2_name
    loser = team_2_name if winner == team_1_name else team_1_name

    # Ustalenie wyniku względem drużyny użytkownika
    if team == team_1_name:
        result = f"{team_1_score}:{team_2_score}"
    else:
        result = f"{team_2_score}:{team_1_score}"  # Odwracamy wynik, jeśli drużyna grała jako gość

    # Przekształcenie wyniku, aby 0:3 i 3:0 traktować identycznie
    standardized_result = "3:0" if result in ["3:0", "0:3"] else \
                          "3:1" if result in ["3:1", "1:3"] else \
                          "3:2" if result in ["3:2", "2:3"] else \
                          "2:3" if result in ["3:2", "2:3"] else \
                          "1:3" if result in ["3:1", "1:3"] else \
                          "0:3"

    opponent = team_1_name if team_1_name != team else team_2_name

    sets = [(set_1_score, set_2_score) for set_1_score, set_2_score in set_scores]

    return {
        "round": round,
        "result": standardized_result,
        "winner": winner == team,
        "sets": sets,
        "date": date.strftime("%d-%m-%Y %H:%M"),
        "team": opponent,
        "logo": f"/assets/teams/{opponent}.png"
    }
