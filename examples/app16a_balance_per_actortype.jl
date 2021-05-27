using Statistics

include("loreco_sim.jl")

balance(a::Actor) = sumsy_balance(a.balance)

function balanceConsumers(a::Actor)::Union{Missing, Number}
    if in(:consumer, getproperty(a, :types)) return sumsy_balance(a.balance)
    else return missing
    end
end

function balanceBakers(a::Actor)::Union{Missing, Number}
    if in(:baker, getproperty(a, :types)) return sumsy_balance(a.balance)
    else return missing
    end
end

function balanceTVMerchants(a::Actor)::Union{Missing, Number}
    if in(:tv_merchant, getproperty(a, :types)) return sumsy_balance(a.balance)
    else return missing
    end
end

function balanceGovernance(a::Actor)::Union{Missing, Number}
    if in(:governance, getproperty(a, :types)) return sumsy_balance(a.balance)
    else return missing
    end
end



function missMinimum(values) return isempty(skipmissing(values)) ? NaN : minimum(skipmissing(values)) end
function missMaximum(values) return isempty(skipmissing(values)) ? NaN : maximum(skipmissing(values)) end
function miss5thPercentile(values) return isempty(skipmissing(values)) ? NaN : quantile(skipmissing(values), 0.05) end
function miss95thPercentile(values) return isempty(skipmissing(values)) ? NaN : quantile(skipmissing(values), 0.95) end
function missMean(values) return isempty(skipmissing(values)) ? NaN : mean(skipmissing(values)) end
function missMedian(values) return isempty(skipmissing(values)) ? NaN : median(skipmissing(values)) end

#::Union{Missing,Float64}
#adata = [(balance,minimum),(balanceConsumers, skippedMissingMinimum),(balance,sum),(balance,maximum), (balance, mean),(balance, median), (balance, std)]
adata= [(balanceConsumers, missMinimum), (balanceConsumers, missMaximum), (balanceConsumers, miss5thPercentile) , (balanceConsumers, miss95thPercentile), (balanceConsumers, missMean), (balanceConsumers, missMedian),
    (balanceBakers, missMinimum), (balanceBakers, missMaximum), (balanceBakers, miss5thPercentile) , (balanceBakers, miss95thPercentile), (balanceBakers, missMean), (balanceBakers, missMedian),
    (balanceTVMerchants, missMinimum), (balanceTVMerchants, missMaximum), (balanceTVMerchants, miss5thPercentile) , (balanceTVMerchants, miss95thPercentile), (balanceTVMerchants, missMean), (balanceTVMerchants, missMedian),
    (balanceGovernance, missMinimum), (balanceGovernance, missMaximum), (balanceGovernance, miss5thPercentile) , (balanceGovernance, miss95thPercentile), (balanceGovernance, missMean), (balanceGovernance, missMedian)]
model = init_loreco_model(SuMSy(2000, 25000, 0.1, 30, seed = 5000),10,1,1)
data, _ = run!(model, actor_step!, econo_model_step!, 5; adata)
print(data[:,:])
