from dash import Dash, html, dcc, Output, Input

import dash_bootstrap_components as dbc
import plotly.graph_objs as go
import dash.dash_table as dt
import plotly.graph_objects as go
from plotly.subplots import make_subplots

from db_requests import get_seasons, check_team_in_season, get_matches_for_team_and_season, get_wins_and_losses
from layouts import create_header, create_team_dropdown, create_season_dropdown, team_in_season_alert, create_match_card


app = Dash(__name__, external_stylesheets=[dbc.themes.BOOTSTRAP, dbc.icons.FONT_AWESOME], assets_folder='assets')


app.layout = html.Div([
    create_header(),
    dbc.Row([
        dbc.Col([create_team_dropdown()]),
        dbc.Col([create_season_dropdown()])
    ]),
    # html.Div([
    #     create_overview_section(),
    # ]),
    team_in_season_alert(),

    dbc.Row([
        dbc.Col([html.Div(id="matches", className="equal-height")], width=6),
        dbc.Col([html.Div(id="pie-chart", className="equal-height")], width=6)
    ])

])


@app.callback(
    Output("alert", "children"),
    Output("alert", "is_open"),
    Input('team-dropdown', 'value'),
    Input('season-slider', 'value'),
)
def show_team(team, idx):
    if team is None or idx is None:
        return "", False

    seasons = get_seasons()
    selected_season = seasons[idx]

    if not check_team_in_season(team, selected_season):
        return f"Team {team} did not play at season {selected_season}.", True

    return "", False



@app.callback(
    Output('matches', 'children'),
    Input('team-dropdown', 'value'),
    Input('season-slider', 'value'),
)
def matches_scores(team, season):
    if not team or season is None:
        return None

    seasons = get_seasons()
    selected_season = seasons[season]

    if check_team_in_season(team, selected_season):
        matches = get_matches_for_team_and_season(team, selected_season)
        for home, away, home_score, away_score in matches:
            print(home, away, home_score, away_score)
        if not matches:
            return html.P("No matches data", style={"color": "gray"})

        return html.Div(
            [
                html.Div(
                    [
                        create_match_card(home, away, home_score, away_score)
                        for home, away, home_score, away_score in matches
                    ],
                    className="scrollable-list"
                )
            ]
        )

    return None



@app.callback(
    Output('pie-chart', 'children'),
    Input('team-dropdown', 'value'),
    Input('season-slider', 'value'),
)
def pie_chart(team, season):
    if not team or season is None:
        return None

    seasons = get_seasons()
    selected_season = seasons[season]

    if check_team_in_season(team, selected_season):
        matches = get_matches_for_team_and_season(team, selected_season)

        if not matches:
            return html.P("Don't have data about matches", style={"color": "gray"})

        wins = sum(1 for match in matches if
                   (match[0] == team and match[2] > match[3]) or (match[1] == team and match[3] > match[2]))
        losses = len(matches) - wins

        fig = go.Figure(
            data=[
                go.Pie(
                    labels=["Wins", "Losses"],
                    values=[wins, losses],
                    marker=dict(colors=["#1f77b4", "#ff7f0e"]),
                )
            ]
        )

        fig.update_layout(title=f"Wyniki {team} w sezonie {selected_season}")
        fig.update_layout(height=450)

        return dcc.Graph(figure=fig)

if __name__ == '__main__':
    app.run(debug=True)