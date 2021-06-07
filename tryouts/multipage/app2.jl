module app2
using DashHtmlComponents, DashCoreComponents

include("app8.jl")

layout = html_div() do
    #dcc_input(id = "input-3", value = "initial value", type = "text"),
    #html_div(id="output-1")
    html_h3("App 2"),
    # represents the URL bar, doesn't render anything
    html_p("dit is app2"),

    dcc_link("Navigate to /", href="/"),
    html_br(),
    dcc_link("Navigate to /page-1", href="app1"),

    # content will be rendered in this element
    html_div(id="output-2")
end

callback!(app, Output("output-2", "children"), Input("url", "pathname")) do pathname

    html_div([
        html_h3("You are on page $(pathname)")
    ])
end
end
