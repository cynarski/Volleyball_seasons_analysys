from dash import html, dcc
import dash_bootstrap_components as dbc
from layouts import (create_header, create_team_dropdown, create_season_dropdown, team_in_season_alert, 
                     create_bracket_layout, more_filters, create_modal, number_of_sets)

def create_layout():
    return html.Div([
        create_header(),
        dbc.Row([
            dbc.Col([create_team_dropdown()]),
            dbc.Col([create_season_dropdown()])
        ]),
        team_in_season_alert(),

        dbc.Row([
            more_filters(),
        ]),
        
    
        dbc.Row([
            dbc.Col([html.Div(id='matches', className='equal-height')], width=6),
            dbc.Col([html.Div(id="pie-chart", className="equal-height")], width=6)
        ]),

        dbc.Row([  # Wykresy wygranych i przegranych
            dbc.Col([dcc.Graph(id="wins-and-losses", className="equal-height", clear_on_unhover=True)], width=12)
        ]),

        dcc.Tooltip(id="graph-tooltip"),

        dbc.Row([
            dbc.Col([html.Div(id="match_results", className="equal-height")], width=6),
            dbc.Col([html.Div(id="season_list", className="equal-height")], width=6)
        ]),

        create_modal(),

        html.Div(id="bracket-container"),
    ]
)
