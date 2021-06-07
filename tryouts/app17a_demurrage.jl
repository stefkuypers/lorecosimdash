using Statistics

include("loreco_sim.jl")

function sumsy_demurrage(balance)::Float64
    demurrages = filter(tuple-> let (time, type, entry, amount, comment)=tuple; startswith(comment, "Demurrage") end,
              collect(balance.transactions))
    return isempty(demurrages) ? 0 : sum(-y[4] for y in demurrages)
end

balance(a::Actor) = sumsy_balance(a.balance)

demurrage(a::Actor) = sumsy_demurrage(a.balance)

#=function sumsy_balance(balance)
    return asset_value(balance, SUMSY_DEP)
    #entry_value(b.balance[asset], entry)
end=#



#::Union{Missing,Float64}
adata = [(demurrage,sum)]
model = init_loreco_model(SuMSy(2000, 7000, 0.1, 30, seed = 5000),1,0,0)
data, _ = run!(model, actor_step!, econo_model_step!, 70; adata)
print(data[:,:])
