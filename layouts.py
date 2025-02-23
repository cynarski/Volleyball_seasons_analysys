from cProfile import label

from dash import  html, dcc
import dash_bootstrap_components as dbc

from db_requests import get_teams_name, get_seasons, check_team_in_season

def create_header():
    return dbc.Card([
        html.Div([
            html.Div([
                html.P([
                    html.I(className='fa-solid fa-volleyball'),
                    " VOLLEYBALL SEASON STATS"
                ])
            ], className="title"),
            html.Img(src='/assets/logoplusliga.jpg', className='image')
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
        ), id='team-dropdown'),
    ], className="team-selact")

def create_season_dropdown():
    seasons = get_seasons()

    marks = {idx: season for idx, season in enumerate(seasons) if idx % 2 == 1 and idx != 1 or idx == 0}
    return dbc.Col([
        dbc.Row(html.Label("Select seson to review")),
        dbc.Row([
            dcc.Slider(
            id='season-slider',
            min=0,
            max=len(seasons) - 1,
            marks=marks,
            value=len(seasons) - 1,
            step=1
        )])

    ], className="season-select")


def create_overview_section():
    return html.Div([
        html.Hr(style={'margin-top': '20px', 'border-top': '1px solid lightgray'}),
        html.H3("OVERVIEW", style={
            'text-align': 'center',
            'color': 'gray',
            'font-weight': 'bold',
            'letter-spacing': '1px'
        })
    ], style={'margin-top': '30px'})


def team_in_season_alert(season):
    return dbc.Alert(f"This team didn't play in a leauge at {season} season.", id="alert", color="danger", is_open=False)

