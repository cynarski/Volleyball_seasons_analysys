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