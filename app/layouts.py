from dash import  html, dcc
import dash_bootstrap_components as dbc

from db_requests import get_teams_name, get_seasons

def create_header():
    return dbc.Card([
        html.Div([
            html.Div([
                html.P([
                    html.I(className='fa-solid fa-volleyball'),
                    " VOLLEYBALL SEASON STATS"
                ])
            ], className="title"),
            html.Img(src='assets/logoplusliga.png', className='image')
        ], className="header")
    ], className="card")

def create_team_dropdown():
    team_options = get_teams_name()

    return dbc.Col([
        dbc.Row(html.Label("Select a team to review")),
        dbc.Row(dcc.Dropdown(
            id='team-dropdown',
            options=team_options,
            value=None,

            placeholder="Select team",
            clearable=True
        ), id='team-dropdown-container'),
    ], className="team-selact")

def create_season_dropdown():
    seasons = get_seasons()

    marks = {idx: season for idx, season in enumerate(seasons)}
    return dbc.Col([
        dbc.Row(html.Label("Select season to review")),
        dbc.Row([
            dcc.Slider(
            id='season-slider',
            min=0,
            max=len(seasons) - 1,
            marks=marks,
            value=None,
            step=1,
        )])

    ], className="season-select")


def team_in_season_alert():
    return dbc.Alert(id="alert", color="danger", is_open=False)


def create_match_card(home, away, home_score, away_score):
    return html.Div([
        html.Span(home, className="team home"),
        html.Img(src=f"/assets/teams/{home}.png", className="team-logo"),
        html.Span(home_score, className="score"),
        html.Span(away_score, className="score"),
        html.Img(src=f"/assets/teams/{away}.png", className="team-logo"),
        html.Span(away, className="team away"),
    ], className="match")


def create_season_table_header():
    return html.Div([
        html.Span("Lp.", className="place"),
        html.Span("Team", className="team-name"),
        html.Span("Pkt", className="points"),
        html.Span("Matches", className="sets"),
        html.Span("Sets", className="sets"),
        html.Span("Ratio", className="sets"),
    ], className="table-header sticky-header")


def create_season_table(place, team, points, total_matches_won, total_matches_lost, total_sets_won, total_sets_lost, sets_ratio, selected_team=False):
    formatted_sets_ratio = f"{sets_ratio:.2f}"

    return html.Div([
        html.Span(place, className="place"),
        html.Img(src=f"/assets/teams/{team}.png", className="team-logo"),
        html.Span(team, className="team-name"),
        html.Span(points, className="points"),
        html.Span(f"{total_matches_won} : {total_matches_lost}", className="sets"),
        html.Span(f"{total_sets_won} : {total_sets_lost}", className="sets"),
        html.Span(formatted_sets_ratio, className="sets"),
    ], className=f"table {'selected-team' if selected_team else ''}")

