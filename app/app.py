from dash import Dash, html, dcc, Output, Input, no_update, State, dash_table
from dash.dependencies import ALL
import dash_bootstrap_components as dbc
import plotly.graph_objs as go

from db_requests import check_team_in_season, get_matches_for_team_and_season, get_sets_scores, get_home_and_away_stats, \
    get_season_table, get_team_sets_stats, get_matches_results, get_match_details_part, get_match_details_all
from layouts import create_header, create_team_dropdown, create_season_dropdown, team_in_season_alert, create_match_card, create_season_table, create_season_table_header
from utils import format_match_result, get_selected_season, get_seasons, is_team_in_season

app = Dash(__name__, external_stylesheets=[dbc.themes.BOOTSTRAP, dbc.icons.FONT_AWESOME], assets_folder='assets')

app.layout = html.Div([
    create_header(),
    dbc.Row([
        dbc.Col([create_team_dropdown()]),
        dbc.Col([create_season_dropdown()])
    ]),
    team_in_season_alert(),

    dbc.Row([
        dbc.Col([html.Div(id='matches', className='equal-height')], width=6),
        dbc.Col([html.Div(id="pie-chart", className="equal-height")], width=6),
    ]),

    dbc.Row([
        dbc.Col([html.Div(id='match-details', className='equal-height scrollable-list', style={'display': 'none'})], width=6),
        dbc.Col([dcc.Graph(id='match-details-chart', style={'display': 'none'})], width=6)
    ]),


    dbc.Row([
        dbc.Col([dcc.Graph(id="wins-and-losses", className="equal-height", clear_on_unhover=True)], width=12)
    ]),

    dcc.Tooltip(id="graph-tooltip"),

    dbc.Row([
            dbc.Col([html.Div(id="match_results", className="equal-height")], width=6),
            dbc.Col([html.Div(id="season_list", className="equal-height")], width=6)
        ]),
])



@app.callback(
    Output("alert", "children"),
    Output("alert", "is_open"),
    Input('team-dropdown', 'value'),
    Input('season-slider', 'value'),
)
def show_team(team, season):
    if team is None or season is None:
        return "", False


    selected_season = get_selected_season(season)

    if not is_team_in_season(team, selected_season):
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

    selected_season = get_selected_season(season)

    if is_team_in_season(team, selected_season):
        matches = get_matches_for_team_and_season(team, selected_season, match_id=True)
        print(matches[0])

        if not matches:
            return html.P("No matches data", style={"color": "gray"})

        cards = []
        for match_id, home, away, home_score, away_score in matches:
            card = html.Div(
                create_match_card(home, away, home_score, away_score),
                id={'type': 'match-card', 'index': match_id},
                n_clicks_timestamp=-1,
                className='clickable-card'
            )
            cards.append(card)
        return html.Div(cards, className='scrollable-list')

    return None


@app.callback(
    Output('pie-chart', 'children'),
    Input('team-dropdown', 'value'),
    Input('season-slider', 'value'),
)
def pie_chart(team, season):
    if not team or season is None:
        return None

    selected_season = get_selected_season(season)

    if is_team_in_season(team, selected_season):
        matches = get_matches_for_team_and_season(team, selected_season)

        if not matches:
            return html.P("Don't have data about matches", style={"color": "gray"})

        wins = sum(1 for match in matches if
                   (match[0] == team and match[2] > match[3]) or (match[1] == team and match[3] > match[2]))
        losses = len(matches) - wins

        fig = go.Figure(
            data=[go.Pie(
                labels=["Wins", "Losses"],
                values=[wins, losses],
                marker=dict(colors=["#1f77b4", "#ff7f0e"]),
            )]
        )

        fig.update_layout(title=f"Wyniki {team} w sezonie {selected_season}")
        fig.update_layout(height=450)

        return dcc.Graph(figure=fig)


@app.callback(
    Output('wins-and-losses', 'figure'),
    Output('wins-and-losses', 'style'),
    Input('team-dropdown', 'value'),
    Input('season-slider', 'value'),
)
def show_wins_and_losses(team, season):

    if not team or season is None:
        return go.Figure(), {'display': 'none'}

    selected_season = get_selected_season(season)

    matches_scores = get_matches_for_team_and_season(team, selected_season, match_id=True, date=True)

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

    fig = go.Figure()

    for match, y in zip(formatted_matches, y_values):
        color = "green" if match["winner"] else "red"
        fig.add_trace(go.Scatter(
            x=[match["round"]],
            y=[y],
            mode="markers",
            marker=dict(size=12, color=color),
            customdata=[[match["logo"], match["team"], match["result"], match["date"], match['sets']]],  # Przygotowanie danych do tooltip
        ))

    fig.update_yaxes(
        tickvals=list(result_map.values()),
        ticktext=list(result_map.keys()),
        title="Result",
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
        height=500
    )

    fig.update_layout(showlegend=False)

    return fig, {'display': 'block'}


@app.callback(
    Output("graph-tooltip", "show"),
    Output("graph-tooltip", "bbox"),
    Output("graph-tooltip", "children"),
    Input("wins-and-losses", "hoverData"),
)
def display_hover(hoverData):
    if hoverData is None:
        return False, no_update, no_update

    pt = hoverData["points"][0]
    bbox = pt["bbox"]

    custom_data = pt["customdata"]
    logo_url = custom_data[0]
    team_name = custom_data[1]
    result = custom_data[2]
    match_date = custom_data[3]
    sets = custom_data[4]

    set_details = [html.P(f"Set {i + 1}: {score[0]} : {score[1]}", style={"text-align": "center"})
                   for i, score in enumerate(sets)]

    children = [
        html.Div([
            html.Img(
                src=logo_url,
                style={"width": "60px", "display": "block", "margin": "auto"}
            ),
            html.H2(
                f"{team_name}",
                style={"color": "darkblue", "overflow-wrap": "break-word", "font-size": "15px", "text-align": "center"}
            ),
            html.P(
                f"Result: {result}",
                style={"text-align": "center"}
            ),
            html.P(
                f"Date: {match_date}",
                style={"text-align": "center", "color": "gray", "font-size": "12px"}
            ),
            html.Div(set_details)
        ], style={'width': '200px', 'white-space': 'normal'})
    ]

    return True, bbox, children


@app.callback(
    Output('match_results', 'children'),
    Input('team-dropdown', 'value'),
    Input('season-slider', 'value'),
)
def match_results(team, season):
    if not team or season is None:
        return None

    selected_season = get_selected_season(season)

    if not is_team_in_season(team, selected_season):
        return html.P("This team didn't play in the selected season.", style={"color": "gray"})

    matches = get_matches_for_team_and_season(team, selected_season)

    if not matches:
        return html.P("Don't have data about matches.", style={"color": "gray"})

    data = get_home_and_away_stats(team, selected_season)

    if not data or len(data) < 4:
        return html.P("No sufficient data for statistics.", style={"color": "gray"})

    x_labels = ["Home Wins", "Home Losses", "Away Wins", "Away Losses"]

    fig = go.Figure()

    fig.add_trace(
        go.Pie(
            labels=x_labels,
            values=[data[0], data[1], data[2], data[3]],
            name="Pie Chart",
            visible=True
        )
    )

    fig.add_trace(
        go.Bar(
            x=x_labels,
            y=[data[0], data[1], data[2], data[3]],
            name="Bar Chart",
            visible=False
        )
    )

    fig.update_layout(
        updatemenus=[
            {
                "buttons": [
                    {"label": "Pie Chart", "method": "update", "args": [
                        {"visible": [True, False]},
                        {"xaxis": {"visible": False}, "yaxis": {"visible": False}}
                    ]},
                    {"label": "Bar Chart", "method": "update", "args": [
                        {"visible": [False, True]},
                        {"xaxis": {"visible": True}, "yaxis": {"visible": True}}
                    ]},
                ],
                "direction": "down",
                "showactive": True,
                "x": 1,
                "y": 0.5,
                "xanchor": "left",
                "yanchor": "middle",
            }
        ],
        title=f"{team} Wins and Losses (Home & Away) - Season {selected_season}",
        height=450,
        plot_bgcolor="white",
        paper_bgcolor="white",
        font=dict(color="black"),
    )

    fig.update_layout(
        xaxis=dict(
            showgrid=True,
            zeroline=True,
            visible=True,
            title="Match Results"
        ),
        yaxis=dict(
            showgrid=True,
            zeroline=True,
            visible=True,
            title="Count"
        ),
    )

    fig.update_layout(
        xaxis=dict(showgrid=False, zeroline=False, visible=False),
        yaxis=dict(showgrid=False, zeroline=False, visible=False),
    )

    return dcc.Graph(figure=fig)


@app.callback(
    Output('season_list', 'children'),
    Input('season-slider', 'value'),
    Input('team-dropdown', 'value')
)
def season_table(season, selected_team_name):
    if not selected_team_name or season is None:
        return None

    selected_season = get_selected_season(season)

    results = get_season_table(selected_season)

    if not results:
        return html.P("No matches data", style={"color": "gray"})

    table_items = [create_season_table_header()]

    for place, team, points in results:
        sets_stats = get_team_sets_stats(team, selected_season)

        matches_stats = get_matches_results(team, selected_season)

        if sets_stats and matches_stats:
            team_name, total_sets_won, total_sets_lost, sets_ratio = sets_stats
            total_matches_won, total_matches_lost = matches_stats


            table_items.append(create_season_table(
                place, team, points,
                total_matches_won=total_matches_won,
                total_matches_lost=total_matches_lost,
                total_sets_won=total_sets_won,
                total_sets_lost=total_sets_lost,
                sets_ratio=sets_ratio,
                selected_team=(team == selected_team_name)
            ))

    return html.Div(
        [
            html.Div(
                table_items,
                className="scrollable-list"
            )
        ]
    )


@app.callback(
    Output('match-details', 'children'),
    Output('match-details', 'style'),
    Output('match-details-chart', 'figure'),
    Output('match-details-chart', 'style'),
    Input({'type': 'match-card', 'index': ALL}, 'n_clicks_timestamp'),
    State({'type': 'match-card', 'index': ALL}, 'id')
)
def display_match_details(timestamps, ids):
    if not timestamps or max(timestamps) <= 0:
        return None, {'display': 'none'}, go.Figure(), {'display': 'none'}

    clicked_idx = timestamps.index(max(timestamps))
    match_id = ids[clicked_idx]['index']

    details = get_match_details_part(match_id)
    full_details = get_match_details_all(match_id)

    category_labels = {
        'score': 'Number of sets won',
        'sum': 'Total points gained',
        'bp': 'Points from counterattack',
        'ratio': 'Points difference',
        'srv_sum': 'Total serves',
        'srv_err': 'Serve errors',
        'srv_ace': 'Aces',
        'srv_eff': 'Serve effectiveness %',
        'rec_sum': 'Receptions',
        'rec_err': 'Reception errors',
        'rec_pos': 'Positive receptions %',
        'rec_perf': 'Perfect receptions %',
        'att_sum': 'Total attacks',
        'att_err': 'Attack errors',
        'att_blk': 'Blocked attacks',
        'att_kill': 'Attack points',
        'att_kill_perc': 'Attack success %',
        'att_eff': 'Attack effectiveness %',
        'blk_sum': 'Block points',
        'blk_as': 'Block assists',
    }

    categories = []
    for key_suffix, label in category_labels.items():
        t1_key = f"t1_{key_suffix}"
        t2_key = f"t2_{key_suffix}"
        if t1_key in full_details and t2_key in full_details:
            categories.append((label, full_details[t1_key], full_details[t2_key]))

    table_columns = [
        {'name': 'Category', 'id': 'category'},
        {'name': full_details['team1'], 'id': 'team1'},
        {'name': full_details['team2'], 'id': 'team2'}
    ]

    table_data = [
        {'category': label, 'team1': t1_val, 'team2': t2_val}
        for label, t1_val, t2_val in categories
    ]

    table = dash_table.DataTable(
        id='match-details-table',
        columns=table_columns,
        data=table_data,
        style_table={'overflowX': 'auto', 'Height': '450px', 'overflowY': 'auto'},
        style_header={'backgroundColor': 'rgb(230, 230, 230)', 'fontWeight': 'bold'},
        style_cell={'textAlign': 'center', 'padding': '5px'},
        row_selectable=False
    )

    categories = ['Aces', 'Blocks', 'Service Errors', 'Attack Errors', 'Attack Efficiency', 'Reception Errors']
    team1_vals = [
        details['t1_ace'], details['t1_blocks'],
        abs(details['t1_srv_sum'] - details['t1_ace']), details['t1_att_err'],
        details['t1_att_eff'], details['t1_rec_err']
    ]
    team2_vals = [
        details['t2_ace'], details['t2_blocks'],
        abs(details['t2_srv_sum'] - details['t2_ace']), details['t2_att_err'],
        details['t2_att_eff'], details['t2_rec_err']
    ]
    fig = go.Figure()
    fig.add_trace(go.Bar(x=categories, y=team1_vals, name=details['team1']))
    fig.add_trace(go.Bar(x=categories, y=team2_vals, name=details['team2']))
    fig.update_layout(title='Match Statistics Comparison', barmode='group',
                      xaxis_title='Category', yaxis_title='Value',
                      legend_title='Teams', plot_bgcolor='white', height=450, width=825)

    table_style = {'display': 'block', 'marginTop': '1rem'}
    chart_style = {'display': 'block', 'marginTop': '1rem'}

    return table, table_style, fig, chart_style



if __name__ == '__main__':
    app.run(debug=True, host="0.0.0.0")
