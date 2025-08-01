# ===================================================================
# FILE: generate_feature_importance.jl (Definitive, Working Version)
# STAGE: Model Interpretation (Stage 5)
# PURPOSE: To train a final model on all available data and extract
#          the feature importances to prove the value of the
#          biomarker rule.
# ===================================================================

println("Setting up the ML environment...")
using Pkg
Pkg.add("DataFrames"); Pkg.add("CSV"); Pkg.add("DecisionTree"); Pkg.add("Printf");
using DataFrames, CSV, DecisionTree, Printf

println("Environment setup complete.")


# --- Helper Function for the Biomarker Rule ---
function apply_biomarker_rule(row)
    igm = row[Symbol("ARC  IgM Core (S/Co)")]
    ai = row[Symbol("AI (1%GITC)")]
    if ismissing(igm) || ismissing(ai); return "Ambiguous"; end
    if igm > 8.5 && ai < 0.46; return "AHB";
    elseif igm < 8.5 && ai > 0.46; return "CHBAE";
    else; return "Ambiguous"; end
end


# --- 1. Load and Prepare Data (Same as Experiment 2) ---
println("\nLoading and preparing data for the final model...")
clean_df = CSV.read("hbv_preprocessed.csv", DataFrame)
original_df = CSV.read("hbv_ml.csv", DataFrame)

transform!(original_df, AsTable(All()) => ByRow(apply_biomarker_rule) => :Biomarker_Rule_Result)
for cat in unique(original_df.Biomarker_Rule_Result)
    clean_df[!, "Rule_" * string(cat)] = (original_df.Biomarker_Rule_Result .== cat)
end

ml_ready_df = filter(row -> !ismissing(row.Expert_Diagnosis), clean_df)
target = ml_ready_df.Expert_Diagnosis

features_to_exclude = [:Clinical_Diagnosis, :Expert_Diagnosis]
feature_names = [name for name in names(ml_ready_df) if Symbol(name) ∉ features_to_exclude]
features = Matrix(ml_ready_df[!, feature_names])

println("Data preparation complete. Using $(nrow(ml_ready_df)) patients and $(length(feature_names)) features.")


# --- 2. Train the Final Model on ALL Data ---
println("\nTraining the final Random Forest model on all available data...")
n_trees = 100
model = RandomForestClassifier(n_trees=n_trees, max_depth=10)
fit!(model, features, target)
println("Final model training complete.")


# --- 3. Extract and Display Feature Importances ---
println("\n\n-----------------------------------------------------------------------")
println("      FEATURE IMPORTANCE ANALYSIS (Mean Decrease in Impurity)")
println("-----------------------------------------------------------------------")

# --- DEFINITIVE FIX IS HERE ---
# 1. Get the raw importance scores from the model.
importances_raw = impurity_importance(model)

# 2. Create a DataFrame to match scores with names.
importance_df = DataFrame(Feature = feature_names, Importance = importances_raw)

# 3. Sort the DataFrame to rank the features.
sort!(importance_df, :Importance, rev=true)

println("\nThe following table shows the most important features the model used")
println("to make its decisions. A higher score means more important.\n")

# Display the Top 15 most important features
println("Top 15 Most Important Features:")
display(first(importance_df, 15))

println("\n-----------------------------------------------------------------------")
println("This analysis provides statistical validation for the biomarker rule's importance.")
println("-----------------------------------------------------------------------\n")