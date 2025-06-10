from dash import  html, dcc
import dash_bootstrap_components as dbc
from db_requests import db_requests

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
    team_options = db_requests.get_teams_name()

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
    seasons = db_requests.get_seasons()

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

def create_match_type_filter(label_style, checklist_style):
    return dbc.Row([
        html.Span("Match type:", style=label_style),
        dbc.RadioItems(
            options=[
                {"label": "Liga", "value": "league"},
                {"label": "Play-off", "value": "play-off"},
            ],
            value="league",
            id="match-type-radio",
            inline=True,
            labelStyle=checklist_style,
        ),
    ], style={'marginTop': '10px', 'alignItems': 'center'})


def create_sets_filter(label_style, checklist_style):
    return dbc.Row([
        html.Span("Number of sets:", style=label_style),
        dbc.Checklist(
            options=[
                {'label': '3 sety', 'value': 3},
                {'label': '4 sety', 'value': 4},
                {'label': '5 setów', 'value': 5},
            ],
            value=[3, 4, 5],
            id='sets-count-checkbox',
            inline=True,
            labelStyle=checklist_style,
        ),
    ], style={'marginTop': '10px', 'alignItems': 'center'})


def create_location_filter(label_style, checklist_style):
    return dbc.Row([
        html.Span("Location:", style=label_style),
        dbc.RadioItems(
            options=[
                {"label": "All", "value": "All"},
                {"label": "Home", "value": "Home"},
                {"label": "Away", "value": "Away"},
            ],
            value="All",
            id="venue-radio",
            inline=True,
            labelStyle=checklist_style,
        ),
    ], style={'marginTop': '10px', 'alignItems': 'center'})


def more_filters():
    label_style = {'fontWeight': 'bold', 'marginRight': '10px', 'fontSize': '16px'}
    checklist_style = {'display': 'inline-block', 'marginRight': '10px'}

    return dbc.Row([
        dbc.Col([
            html.Div(
                [
                    html.Span("More filters", className="filters-label"),
                    html.Div(className="filters-line"),
                    dbc.Button(
                        html.I(className="fa fa-chevron-down"),
                        id="toggle-filters-btn",
                        color="link",
                        outline=False,
                        size="sm",
                        className="filters-arrow-btn"
                    ),
                ],
                className="filters-bar"
            ),
            dbc.Collapse(
                id="filters-collapse",
                is_open=False,
                children=[
                    create_match_type_filter(label_style, checklist_style),
                    create_sets_filter(label_style, checklist_style),
                    create_location_filter(label_style, checklist_style),
                ],
                className="filters-collapse"
            ),
        ], width=12, className="team-selact")
    ])
def number_of_sets():
    return dcc.RadioItems(
        id='sets-count-radio',
        options=[
            {'label': '3 sety', 'value': 3},
            {'label': '4 sety', 'value': 4},
            {'label': '5 setów', 'value': 5},
        ],
        value=3,  # domyślna wartość
        labelStyle={'display': 'inline-block', 'margin-right': '10px'}
    ),

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

def create_modal():
    return html.Div(
        id='modal',
        className='modal',
        children=[
            html.Div(
                className='modal-content',
                children=[
                    html.Button(
                        "✕",
                        id='close-modal',
                        n_clicks=0,
                        className='close-modal-button'
                    ),
                    html.Div(id='match-stats')
                ]
            )
        ]
    )

def create_match_stats_table(details):

    print(details)
    return html.Div([
        html.Table([

            html.Tr([
                html.Td(html.Img(src=f"/assets/teams/{details['team1']}.png", style=logo_style()), style=cell_base_style()),
                html.Td(details['team1'], style=team_name_style(), colSpan=1),
                html.Td(details['team2'], style=team_name_style(), colSpan=1),
                html.Td(html.Img(src=f"/assets/teams/{details['team2']}.png", style=logo_style()), style=cell_base_style()),
            ]),

            html.Tr([
                html.Td("Serve", colSpan=4, style=section_header_style())
            ]),

            html.Tr([
                html.Td(str(int(details['t1_ace'])), style=value_cell_style()),
                html.Td("Aces", style=label_style(), colSpan=2),
                html.Td(str(int(details['t2_ace'])), style=value_cell_style())
            ]),

            html.Tr([
                html.Td(str(int(details['t1_srv_err'])), style=value_cell_style()),
                html.Td("Errors", style=label_style(), colSpan=2),
                html.Td(str(int(details['t2_srv_err'])), style=value_cell_style())
            ]),

            html.Tr([
                html.Td("Reception", colSpan=4, style=section_header_style())
            ]),

            html.Tr([
                html.Td(f"{str(int(details['t1_rec_pos']))}%", style=value_cell_style()),
                html.Td("Positive", style=label_style(), colSpan=2),
                html.Td(f"{str(int(details['t2_rec_pos']))}%", style=value_cell_style())
            ]),

            html.Tr([
                html.Td(f"{str(int(details['t1_rec_perf']))}%", style=value_cell_style()),
                html.Td("Perfection", style=label_style(), colSpan=2),
                html.Td(f"{str(int(details['t2_rec_perf']))}%", style=value_cell_style())
            ]),

            html.Tr([
                html.Td("Attack", colSpan=4, style=section_header_style())
            ]),

            html.Tr([
                html.Td(str(int(details['t1_att_err'])), style=value_cell_style()),
                html.Td("Errors", style=label_style(), colSpan=2),
                html.Td(str(int(details['t2_att_err'])), style=value_cell_style())
            ]),

            html.Tr([
                html.Td(f"{str(int(details['t1_att_perc']))}%", style=value_cell_style()),
                html.Td("Accuracy", style=label_style(), colSpan=2),
                html.Td(f"{str(int(details['t2_att_perc']))}%", style=value_cell_style())
            ]),

            html.Tr([
                html.Td("Blocks", colSpan=4, style=section_header_style())
            ]),

            html.Tr([
                html.Td(str(int(details['t1_blocks'])), style=value_cell_style()),
                html.Td("Blocks", style=label_style(), colSpan=2),
                html.Td(str(int(details['t2_blocks'])), style=value_cell_style())
            ]),
        ], style={
            'width': '100%',
            'borderCollapse': 'collapse',
            'marginTop': '15px'
        })
    ], style={
        'backgroundColor': 'white',
        'borderRadius': '10px',
        'padding': '20px'
    })

def logo_style():
    return {
        'height': '40px',
        'display': 'block',
        'margin': 'auto'
    }

def team_name_style():
    return {
        'textAlign': 'center',
        'fontWeight': '600',
        'fontSize': '18px',
        'padding': '10px 0'
    }

def section_header_style():
    return {
        'textAlign': 'center',
        'fontWeight': 'bold',
        'fontSize': '16px',
        'padding': '10px 0',
        'borderTop': '1px solid #ddd',
        'borderBottom': '1px solid #ddd',
        'backgroundColor': '#fafafa'
    }

def value_cell_style():
    return {
        'textAlign': 'center',
        'fontWeight': 'bold',
        'fontSize': '16px',
        'padding': '10px 0'
    }

def label_style():
    return {
        'textAlign': 'center',
        'fontSize': '15px',
        'color': '#444',
        'padding': '8px 0'
    }

def cell_base_style():
    return {
        'textAlign': 'center',
        'padding': '10px'
    }

