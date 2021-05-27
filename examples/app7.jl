using Dash, DashHtmlComponents, DashCoreComponents

app = dash()

app.layout = html_div() do
    #dcc_input(id = "input-3", value = "initial value", type = "text"),
    #html_div(id="output-1")

    # represents the URL bar, doesn't render anything
    dcc_location(id="url"),

    dcc_link("Navigate to /", href="/"),
    html_br(),
    dcc_link("Navigate to /page-2", href="/page-2"),

    # content will be rendered in this element
    html_div(id="page-content")
end

callback!(app, Output("page-content", "children"), Input("url", "pathname")) do pathname
    html_div([
        html_h3("You are on page $(pathname)")        
    ])
end



run_server(app, "0.0.0.0", debug=true)
