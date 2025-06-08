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

def more_filters():
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
                    dbc.RadioItems(
                        options=[
                            {"label": "Liga", "value": "league"},
                            {"label": "Play-off", "value": "play-off"},
                        ],
                        value="league",
                        id="match-type-radio",
                        inline=True,
                    )
                ],
                className="filters-collapse"
            ),
        ], width=12, className="team-selact")
    ])

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


def match(label, team1_seed, team1_name, team1_sets, team2_seed, team2_name, team2_sets, grid_row):
    return html.Div([
        html.Div(label, className='match-label-play-off'),
        html.Div([
            html.Span(str(team1_seed), className='team-seed-play-off'),
            html.Span(team1_name, className='team-name-play-off'),
            html.Span(team1_sets, className='team-sets-play-off'),
        ], className='team-play-off'),
        html.Div([
            html.Span(str(team2_seed), className='team-seed-play-off'),
            html.Span(team2_name, className='team-name-play-off'),
            html.Span(team2_sets, className='team-sets-play-off'),
        ], className='team-play-off'),
    ], className='match-play-off', style={'gridRow': grid_row})

def create_bracket_layout(top_teams):
    seeds = {place: name for place, name, _ in top_teams}
    sets = {place: "" for place in range(1, 9)}  # Uzupełnij jeśli masz wyniki setów

    return html.Div([
        html.H2("Drabinka turniejowa", style={'textAlign': 'center'}),
        html.Div([
            # Ćwierćfinały
            html.Div([
                match("Ćwierćfinał", 1, seeds.get(1, ""), sets.get(1, ""), 8, seeds.get(8, ""), sets.get(8, ""), '1'),
                match("Ćwierćfinał", 2, seeds.get(2, ""), sets.get(2, ""), 7, seeds.get(7, ""), sets.get(7, ""), '3'),
                match("Ćwierćfinał", 3, seeds.get(3, ""), sets.get(3, ""), 6, seeds.get(6, ""), sets.get(6, ""), '5'),
                match("Ćwierćfinał", 4, seeds.get(4, ""), sets.get(4, ""), 5, seeds.get(5, ""), sets.get(5, ""), '7'),
            ], className='round-grid'),
            # Półfinały
            html.Div([
                match("Półfinał", 1, seeds.get(1, ""), "", 4, seeds.get(4, ""), "", '2'),
                match("Półfinał", 2, seeds.get(2, ""), "", 3, seeds.get(3, ""), "", '6'),
            ], className='round-grid'),
            # Finał i mecz o 3. miejsce
            html.Div([
                match("Finał", 1, seeds.get(1, ""), "", 2, seeds.get(2, ""), "", '3'),
                match("Mecz o 3. miejsce", 3, seeds.get(3, ""), "", 4, seeds.get(4, ""), "", '5'),
            ], className='round-grid'),
        ], className='bracket-play-off', style={'backgroundColor': '#eafdff'})
    ])

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

