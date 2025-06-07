from db_requests import (
    get_matches_for_team_and_season, get_sets_scores, get_home_and_away_stats,
    get_season_table, get_team_sets_stats, get_matches_results, get_match_details
)
from utils import format_match_result, get_selected_season, is_team_in_season

class TeamService:
    @staticmethod
    def is_team_in_season(team, season):
        return is_team_in_season(team, season)

class SeasonService:
    @staticmethod
    def get_selected_season(season):
        return get_selected_season(season)

class MatchService:
    @staticmethod
    def get_matches_for_team_and_season(team, season, **kwargs):
        return get_matches_for_team_and_season(team, season, **kwargs)

    @staticmethod
    def get_sets_scores(match_id):
        return get_sets_scores(match_id)

    @staticmethod
    def get_match_details(match_id):
        return get_match_details(match_id)

class StatsService:
    @staticmethod
    def get_home_and_away_stats(team, season):
        return get_home_and_away_stats(team, season)

    @staticmethod
    def get_season_table(season):
        return get_season_table(season)

    @staticmethod
    def get_team_sets_stats(team, season):
        return get_team_sets_stats(team, season)

    @staticmethod
    def get_matches_results(team, season):
        return get_matches_results(team, season)

    @staticmethod
    def format_match_result(match, sets, team, index):
        return format_match_result(match, sets, team, index)