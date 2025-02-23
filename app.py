from dash import Dash, html, dcc, Output, Input

import dash_bootstrap_components as dbc
from db_requests import get_seasons, check_team_in_season
from layouts import create_header, create_team_dropdown, create_season_dropdown, team_in_season_alert


app = Dash(__name__, external_stylesheets=[dbc.themes.BOOTSTRAP, dbc.icons.FONT_AWESOME])


app.layout = html.Div([
    create_header(),
    dbc.Row([
        dbc.Col([create_team_dropdown()]),
        dbc.Col([create_season_dropdown()])
    ]),
    # html.Div([
    #     create_overview_section(),
    # ]),
    team_in_season_alert()

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
    if  not check_team_in_season(team, selected_season):
        return f"Team {team} did not play at season {selected_season}.", True
    return "", False


if __name__ == '__main__':
    app.run(debug=True)