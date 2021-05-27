using Dash, DashBootstrapComponents

app = dash(external_stylesheets=[dbc_themes.BOOTSTRAP])

app.layout = dbc_container(
    html_div([
        dbc_row(dbc_col([html_div("A single column"),
        dbc_alert("Hello Bootstrap!", color="success")])),
        dbc_row(
            [
                dbc_col(html_div("One of three columns"), width=6),
                dbc_col(html_div("One of three columns")),
                dbc_col(html_div("One of three columns")),
            ]
        ),
    ]),
    className="p-5",

)

run_server(app, "0.0.0.0", 8050)
