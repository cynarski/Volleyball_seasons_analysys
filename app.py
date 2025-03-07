from turtledemo.penrose import start

from dash import Dash, html, dcc, Output, Input

import dash_bootstrap_components as dbc
import plotly.graph_objs as go
import plotly.graph_objects as go

from db_requests import get_seasons, check_team_in_season, get_matches_for_team_and_season, get_wins_and_losses, get_sets_scores
from layouts import create_header, create_team_dropdown, create_season_dropdown, team_in_season_alert, create_match_card
from utils import format_match_result

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
    ]),
    dbc.Row([
        dbc.Col([html.Div(id="wins-and-losses", className="equal-height")], width=12)
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

@app.callback(
    Output('wins-and-losses', 'children'),
    Input('team-dropdown', 'value'),
    Input('season-slider', 'value'),
)
def show_wins_and_losses(team, season):

    if not team or season is None:
        return None

    seasons = get_seasons()
    selected_season = seasons[season]

    matches_scores = get_matches_for_team_and_season(team, selected_season,match_id=True, date=True)

    set_scores = []

    for match in matches_scores:
        result = get_sets_scores(match[0])
        set_scores.append(result)

    formatted_matches = []
    for index, (match, sets) in enumerate(zip(matches_scores, set_scores), start=1):
        formatted_match = format_match_result(match, sets, team, index)
        formatted_matches.append(formatted_match)

    result_map = {"3:0": 5, "3:1": 4, "3:2": 3, "2:3": 2, "1:3": 1, "0:3": 0}
    y_values = [result_map[m["result"]] for m in formatted_matches]

    # Tworzenie wykresu
    fig = go.Figure()

    for match, y in zip(formatted_matches, y_values):
        # Kolor punktu (zielony - wygrana, czerwony - przegrana)
        color = "green" if match["winner"] else "red"
        if len(match['sets']) > 0:
            hover_text = f"""
            <img src={match["logo"]} style='width:50px;height:50px;'><br>
            <b>{match['team']}</b><br>
            <b style='font-size:20px;'>{match['result']}</b><br>
            Set 1: {match['sets'][0][0]} : {match['sets'][0][1]}<br>
            Set 2: {match['sets'][1][0]} : {match['sets'][1][1]}<br>
            Set 3: {match['sets'][2][0]} : {match['sets'][2][1]}<br>
            {match['date']}
            """

        fig.add_trace(go.Scatter(
            x=[match["round"]],
            y=[y],
            mode="markers",
            marker=dict(size=12, color=color),
            text=[hover_text],
            hoverinfo="text",
            hoverlabel=dict(align="left"),
        ))

    fig.update_yaxes(
        tickvals=list(result_map.values()),
        ticktext=list(result_map.keys()),
        title="Wyniki",
        showgrid=True
    )

    fig.update_xaxes(
        title="Rounds",
        tickmode="linear",
        dtick=1
    )

    fig.update_layout(
        title="Matches Results",
        plot_bgcolor="white",
        height=450,
        width=1780
    )

    fig.update_layout(showlegend=False)

    # Wyświetlenie wykresu
    return dcc.Graph(figure=fig)


if __name__ == '__main__':
    app.run(debug=True)