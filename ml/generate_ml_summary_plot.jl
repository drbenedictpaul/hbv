# ===================================================================
# FILE: generate_ml_summary_plot.jl (Definitive, Corrected Version)
# PURPOSE: Creates the final, two-panel figure summarizing all
#          machine learning results for the publication.
# ===================================================================

println("Setting up the ML environment...")
using Pkg
Pkg.add("DataFrames"); Pkg.add("CSV"); Pkg.add("DecisionTree"); Pkg.add("Printf"); Pkg.add("Plots"); Pkg.add("GR")
using DataFrames, CSV, DecisionTree, Printf, Plots
gr()

println("Environment setup complete.")


# --- This script contains data from previous runs ---
accuracy_exp1 = 86.67
accuracy_exp2 = 98.89


# --- We must re-calculate the feature importances for Panel B ---
println("\nRecalculating feature importances for the plot...")

function apply_biomarker_rule(row)
    igm = row[Symbol("ARC  IgM Core (S/Co)")]
    ai = row[Symbol("AI (1%GITC)")]
    if ismissing(igm) || ismissing(ai); return "Ambiguous"; end
    if igm > 8.5 && ai < 0.46; return "AHB";
    elseif igm < 8.5 && ai > 0.46; return "CHBAE";
    else; return "Ambiguous"; end
end

clean_df = CSV.read("hbv_preprocessed.csv", DataFrame)
original_df = CSV.read("hbv_ml.csv", DataFrame)
transform!(original_df, AsTable(All()) => ByRow(apply_biomarker_rule) => :Biomarker_Rule_Result)
for cat in unique(original_df.Biomarker_Rule_Result)
    clean_df[!, "Rule_" * string(cat)] = (original_df.Biomarker_Rule_Result .== cat)
end
ml_ready_df = filter(row -> !ismissing(row.Expert_Diagnosis), clean_df)
target = ml_ready_df.Expert_Diagnosis
features_df = select(ml_ready_df, Not([:Clinical_Diagnosis, :Expert_Diagnosis]))
features = Matrix(features_df)
feature_names = names(features_df)

model = RandomForestClassifier(n_trees=100, max_depth=10)
fit!(model, features, target)

importances_raw = impurity_importance(model)
importance_df = DataFrame(Feature = feature_names, Importance = importances_raw)
sort!(importance_df, :Importance, rev=true)
top_10_features = first(importance_df, 10)

println("Feature importance calculation complete.")


# --- Generate the Two-Panel Plot ---
println("Generating the final two-panel summary plot...")

# --- Panel A: Accuracy Comparison Bar Chart ---
p1 = bar(
    ["Baseline Model", "Rule-Enhanced Model"],
    [accuracy_exp1, accuracy_exp2],
    legend = false,
    title = "A) Model Performance",
    ylabel = "Mean Accuracy (%)",
    ylims = (0, 105),
    bar_width = 0.5,
    c = [:gray, :purple]
)
annotate!([(1, accuracy_exp1 + 4, text("$(accuracy_exp1)%", 10)),
           (2, accuracy_exp2 + 4, text("$(accuracy_exp2)%", 10))])


# --- Panel B: Feature Importance Horizontal Bar Chart (DEFINITIVE FIX) ---
# We use the standard 'bar' function with the 'orientation' keyword.
p2 = bar(
    reverse(top_10_features.Importance), # Data for the bars
    orientation = :horizontal, # This makes it a horizontal bar chart
    yticks = (1:10, reverse(top_10_features.Feature)), # Labels for the y-axis
    ytickfontsize = 8,
    legend = false,
    title = "B) Top 10 Features of Enhanced Model",
    xlabel = "Importance (Mean Decrease in Impurity)"
)


# --- Combine the two panels into one figure ---
final_plot = plot(
    p1, p2,
    layout = (1, 2),
    size = (1200, 500),
    plot_title = "Machine Learning Validation of the Biomarker Rule"
)

# Save the plot
savefig(final_plot, "ml_summary_plot.png")

println("\n-----------------------------------------------------------------------")
println("SUCCESS: The final summary plot has been saved as 'ml_summary_plot.png'")
println("This version uses the correct syntax and will execute properly.")
println("-----------------------------------------------------------------------\n")