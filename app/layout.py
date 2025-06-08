from dash import html, dcc
import dash_bootstrap_components as dbc
from layouts import create_header, create_team_dropdown, create_season_dropdown, team_in_season_alert, create_bracket_layout, more_filters

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

        html.Div(
            id='modal',
            style={
                'display': 'none',
                'position': 'fixed',
                'zIndex': 10,
                'left': 0,
                'top': 0,
                'width': '100%',
                'height': '100%',
                'overflow': 'auto',
                'backgroundColor': 'rgba(0,0,0,0.4)'
            },
            children=[
                html.Div(
                    style={
                        'position': 'relative',
                        'backgroundColor': '#fff',
                        'margin': '10% auto',
                        'padding': 20,
                        'border': '1px solid #888',
                        'width': '100%',
                        'maxWidth': '800px',
                        'borderRadius': '8px',
                        'boxShadow': '0 5px 15px rgba(0,0,0,0.3)'
                    },
                    children=[
                        html.Button(
                            "✕",
                            id='close-modal',
                            n_clicks=0,
                            style={
                                "position": "absolute",
                                "top": "12px",
                                "right": "20px",
                                "background": "none",
                                "border": "none",
                                "fontSize": "2rem",
                                "cursor": "pointer",
                                "color": "#888",
                                "zIndex": 11
                            }
                        ),
                        # This is where the table will be inserted dynamically
                        html.Div(id='match-stats')
                    ]
                )
            ]
        ),
        html.Div(id="bracket-container"),
    ]
)
