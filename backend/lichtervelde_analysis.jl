using CSV
using EconoSim
using DataFrames
using Plots
using StatsPlots

@enum Direction incoming=1 outgoing=2 both=3

function direction_str(direction::Direction)
    if direction == incoming
        "inkomend"
    elseif direction == outgoing
        "uitgaand"
    else
        "inkomend/uitgaand"
    end
end

HANDELAARS = "Handelaars"
BURGERS = "Burgers"
BEGUNSTIGDEN = "Begunstigden"

PAY = "Betaling"
GI = "Gegarandeerd inkomen"
INJ = "INJ"
DEM = "Demurrage"
CONTR = "Contributie"
EUR = "Euro aankoop"

# Loreco analysis

function update_anon_dict(anon_dict, key, id_seq)
    if !(key in keys(anon_dict))
        anon_dict[key] = string(id_seq)
        id_seq += 1
    end

    return id_seq
end

function transaction_type(from::String, type::String, description::String, amount::String)
    if type == "Digitale klavers" &&
        description == "Digitale klavers ontvangen van de Administratie"
        if amount == "16,00" || amount == "32,00"
            return GI
        else
            return GI
        end
    elseif contains(type, "Inkomen")
        return GI
    elseif contains(description, "Jouw munten")
        return GI
    elseif contains(description, "gegarandeerd inkomen")
        return GI
    elseif type == "Digitale klavers" && contains(description, GI)
        return GI
    elseif type == "Digitale klavers" && contains(description, "Klavers voor de 3 voorbije maanden")
        return GI
    elseif contains(type, "Betaling")
        return PAY
    elseif type == "Omzetting Euro´s naar Klavers"
        return EUR
    elseif type == "Systeemstabiliteit"
        return DEM
    elseif contains(type, "Demurrage")
        return CONTR
    elseif from == "Digitale Klavers"
        return GI
    else
        return type * " - " * description
    end
end

function transaction_type(from::String, type::String, description::Missing, amount::String)
    return transaction_type(from, type, "", amount)
end

function read_users()
    user_file = CSV.File("/Users/stef/Programming/Visual Studio/lorecosimdash/datasets/users-search.csv")
    id_dict = Dict{String, Tuple{Integer, String, String}}()
    id_dict["Gemeenschapsbijdrage"] = (1111, "G", "")
    id_dict["Digitale Klavers"] = (2222, "DK", "")
    id_dict["Lichtervelde Koopt Lokaal"] = (3333, "LOK", "")
    id_dict["Brochetje"] = (9999, HANDELAARS, "")

    for i in 1:length(user_file)
        id_dict[user_file.name[i]] = (user_file.username[i],
                                        user_file.group[i],
                                        user_file.email[i])
    end

    return id_dict
end

function read_data()
    transaction_file = CSV.File("/Users/stef/Programming/Visual Studio/lorecosimdash/datasets/transfers-overview.csv")

    # Anonymise data
    id_dict = read_users()

    df = DataFrame(date = String[],
                    month = String[],
                    from_id = Integer[],
                    from_type = String[],
                    to_id = Integer[],
                    to_type = String[],
                    amount = Currency[],
                    transaction_type = String[])

    for i in 1:length(transaction_file)
        push!(df, [first(transaction_file.date[i], 10),
                    last(first(transaction_file.date[i], 10), 7),
                    id_dict[transaction_file.fromOwner[i]][1],
                    id_dict[transaction_file.fromOwner[i]][2],
                    id_dict[transaction_file.toOwner[i]][1],
                    id_dict[transaction_file.toOwner[i]][2],
                    parse(Currency, replace(transaction_file.amount[i], "," => ".")),
                    transaction_type(string(transaction_file.fromOwner[i]),
                                        string(transaction_file.type[i]),
                                        string(transaction_file.description[i]),
                                        string(transaction_file.amount[i]))])
    end

    return df
end

function count_types()
    user_types = values(read_users())

    return (Handelaars = count(i -> (i[2] == HANDELAARS), user_types),
            Burgers = count(i -> (i[2] == BURGERS), user_types),
            Begunstigden = count(i -> (i[2] == BEGUNSTIGDEN), user_types))
end

"""
Read all data in an easy accessible tree of dictionaries.
Structure:
    User id
        -> :type (:Handelaars, :Begunstigden, :Burgers, :Admin)
        -> :name
        -> :email
        -> :to
            -> to_id
                -> month
                    -> amount
        -> :from
            -> from_id
                -> month
                    -> amount
"""
function create_data_dict()
    data = read_data()
    users = read_users()
    data_dict = Dict{Integer, Dict{Symbol, Any}}()

    for pair in pairs(users)
        user_dict = Dict{Symbol, Any}()
        
        user_dict[:name] = pair[1]
        user_dict[:type] = pair[2][2]
        user_dict[:email] = pair[2][3]
        user_dict[:to] = Dict{Integer, Dict{String, Currency}}()
        user_dict[:from] = Dict{Integer, Dict{String, Currency}}()
        data_dict[pair[2][1]] = user_dict
    end

    groups = groupby(data, :month)

    for group in groups
        rows = eachrow(group)

        for i in 1:length(rows)
            row = rows[i]

            if row[:transaction_type] == PAY
                from_user = data_dict[row[:from_id]]
                month_dict = get!(from_user[:to], row[:to_id], Dict{String, Currency}())
                get!(month_dict, row[:month], CUR_0)
                month_dict[row[:month]] += row[:amount]
                
                to_user = data_dict[row[:to_id]]
                month_dict = get!(to_user[:from], row[:from_id], Dict{String, Currency}())
                get!(month_dict, row[:month], CUR_0)
                month_dict[row[:month]] += row[:amount]
            end
        end
    end

    return data_dict
end

function get_inactive_accounts(type = nothing)
    user_data = create_data_dict()
    inactive_accounts = []

    for user in values(user_data)
        if isempty(keys(user[:to])) && isempty(keys(user[:from])) && !isempty(user[:email])
            if isnothing(type) || user[:type] == type
                push!(inactive_accounts, (user[:name], user[:email]))
            end
        end
    end

    return inactive_accounts
end

function plot_active_accounts(type::String)
    
end

function plot_aggregate(type::String)
    transactions_in = 0
    amount_in = CUR_0
    transaction_out = 0
    amount_out = CUR_0

    for i in 1:size(data)[1]
        if data[i, :transaction_type] == PAY
            if data[i, :from_type] == type
                transaction_out += 1
                amount_out += data[i, :amount]
            elseif data[i, :to_type] == type
                transactions_in += 1
                amount_in += data[i, :amount]
            end
        end
    end

    return transactions_in, amount_in, transaction_out, amount_out
end

function analyse_transaction_amount(data = read_data(); transaction_type)
    total = CUR_0

    for i in 1:size(data)[1]
        if data[i, :transaction_type] == transaction_type
            total += data[i, :amount]
        end
    end

    return total
end

function analyse_other(data = read_data())
    total = CUR_0
    transactions = 0
    list = []

    for i in 1:size(data)[1]
        if !(data[i, :transaction_type] in [GI, PAY, GI, DEM, CONTR, EUR])
            transactions += 1
            total += data[i, :amount]
            push!(list, data[i, :transaction_type])
        end
    end

    return transactions, total, list
end

function collect_activities!(rows, type, d_id, d_type, transaction_type, activity::Dict{Integer, Integer})
    for i in 1:length(rows)
        row = rows[i]

        if row[:transaction_type] == transaction_type && row[d_type] == type
            if row[d_id] in keys(activity)
                activity[row[d_id]] += 1
            else
                activity[row[d_id]] = 1
            end
        end
    end
end

function analyse_activity(data = read_data(); transaction_type = PAY, types = [HANDELAARS, BURGERS, BEGUNSTIGDEN], direction::Direction)
    types_dict = Dict{String, Dict{Integer, Integer}}() # type => activity

    for type in types
        types_dict[type] = Dict{Integer, Integer}()
    end

    rows = eachrow(data)

    if direction == both || direction == outgoing
        d_id = :from_id
        d_type = :from_type

        for type in keys(types_dict)
            collect_activities!(rows, type, d_id, d_type, transaction_type, types_dict[type])
        end
    end

    if direction == both || direction == incoming
        d_id = :to_id
        d_type = :to_type

        for type in keys(types_dict)
            collect_activities!(rows, type, d_id, d_type, transaction_type, types_dict[type])
        end
    end

    activity = DataFrame(type = String[],
                        actief = Integer[],
                        inactief = Integer[])
    all_types = count_types()

    for type in keys(types_dict)
        dict = types_dict[type]
        active = 0
        inactive = 0

        for key in keys(dict)
            if dict[key] != 0
                active += 1
            end
        end

        inactive = all_types[Symbol(type)] - active

        push!(activity, [type active inactive])
    end

    return activity
end

function analyse_transactions(data, type::String; direction::Direction, transaction_type = PAY)
    activity = Dict{Integer, Integer}() # id => num_transactions

    rows = eachrow(data)

    if direction == both || direction == outgoing
        d_id = :from_id
        d_type = :from_type
        collect_activities!(rows, type, d_id, d_type, transaction_type, activity)
    end

    if direction == both || direction == incoming
        d_id = :to_id
        d_type = :to_type
        collect_activities!(rows, type, d_id, d_type, transaction_type, activity)
    end

    frequency = Dict{Integer, Integer}() # num_transaction => num_accounts

    for key in keys(activity)
        if activity[key] in keys(frequency)
            frequency[activity[key]] += 1
        else
            frequency[activity[key]] = 1
        end
    end

    transactions = DataFrame(num_accounts = Integer[],
                            num_transactions = Integer[])

    for key in keys(frequency)
        push!(transactions, [frequency[key] key])
    end

    return sort(transactions)
end

function plot_transactions(type::String; direction::Direction, transaction_type = PAY)
    data = analyse_transactions(read_data(), type, transaction_type = transaction_type, direction = direction)

    if !isempty(data)
        bar(data[!, :num_transactions],
            data[!, :num_accounts],
            title = type * " " * direction_str(direction)* " " * transaction_type,
            label = "Aantal " * type,
            xlabel = "Aantal transacties",
            xtick = 1:1000,
            ytick = 1:1000)
    end
end

function plot_activity(type::String; direction::Direction, transaction_type = PAY, plot_active = true, plot_inactive = true)
    data = read_data()

    groups = groupby(data, :month)
    months = []
    active = Vector{Integer}()
    inactive = Vector{Integer}()

    for group in groups
        append!(months, group[!, :month][1])
        activity = analyse_activity(group, direction = direction, types = [type], transaction_type = transaction_type)
        append!(active, activity[!, :actief][1])
        append!(inactive, activity[!, :inactief][1])
    end

    a_plot = plot(title = type * " " * transaction_type * "\n" * direction_str(direction),
        xlabel = "Maanden vanaf start",
        ylabel = "Aantal accounts",
        xticks = 0:1000,
        yticks = 1:1000)

    if plot_active
        plot!(active,
            label = :none)
    end

    if plot_inactive
        plot!(inactive,
            label = :none)
    end

    return a_plot
end

function plot_accounts(type::String, transaction_type = PAY)
    data = read_data()

    rows = eachrow(data)
    user_dict = Dict{Integer, Vector{Integer}}() # id => [total, in, out]

    users = read_users()

    for v in values(users)
        if v[2] == type
            user_dict[v[1]] = [0, 0, 0]
        end
    end

    for i in 1:length(rows)
        row = rows[i]

        if row[:transaction_type] == transaction_type
            if row[:from_type] == type
                user_dict[row[:from_id]][1] += 1
                user_dict[row[:from_id]][3] += 1
            end

            if row[:to_type] == type
                user_dict[row[:to_id]][1] += 1
                user_dict[row[:to_id]][2] += 1
            end
        end
    end

    transactions = Vector{Vector}()
    for v in values(user_dict)
        push!(transactions, v)
    end

    reverse!(sort!(transactions))
    all_tx = []
    in_tx = []
    out_tx = []

    for i in 1:length(transactions)
        append!(all_tx, transactions[i][1])
        append!(in_tx, transactions[i][2])
        append!(out_tx, transactions[i][3])
    end

    plot(title = "Accounts " * type,
        xlabel = "",
        xticks = 0:5:1000,
        yticks = 1:1000)
    plot!(all_tx, label = "Totaal transacties", marker = :circle)
    plot!(in_tx, label = "Inkomend", color = :green, marker = :circle)
    plot!(out_tx, label = "Uitgaand", color = :red, marker = :circle)
end