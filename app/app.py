from dash import Dash
import dash_bootstrap_components as dbc
from layout import create_layout
from callbacks import register_callbacks


def create_app():
    app = Dash(
        __name__,
        external_stylesheets=[dbc.themes.BOOTSTRAP, dbc.icons.FONT_AWESOME],
        assets_folder='assets'
    )
    app.layout = create_layout()
    register_callbacks(app)
    return app


if __name__ == '__main__':
    app = create_app()
    app.run(debug=True, host="0.0.0.0")