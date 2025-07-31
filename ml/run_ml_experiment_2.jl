# ===================================================================
# FILE: run_ml_experiment_2.jl
# STAGE: Model Training (Experiment 2)
# PURPOSE: To build and evaluate a "Rule-Enhanced" model that
#          predicts the correct Expert Diagnosis.
# ===================================================================

println("Setting up the ML environment...")
using Pkg
Pkg.add("DataFrames"); Pkg.add("CSV"); Pkg.add("DecisionTree"); Pkg.add("Random"); Pkg.add("Printf")
using DataFrames, CSV, DecisionTree, Random, Printf

println("Environment setup complete.")


# --- Helper Function for the Biomarker Rule ---
# This function defines your rule for AHB vs CHBAE
function apply_biomarker_rule(row)
    igm = row[Symbol("ARC  IgM Core (S/Co)")]
    ai = row[Symbol("AI (1%GITC)")]
    if ismissing(igm) || ismissing(ai); return "Ambiguous"; end
    if igm > 8.5 && ai < 0.46; return "AHB";
    elseif igm < 8.5 && ai > 0.46; return "CHBAE";
    else; return "Ambiguous"; end
end


# --- 1. Load Data ---
println("\nLoading preprocessed data ('hbv_preprocessed.csv')...")
clean_df = CSV.read("hbv_preprocessed.csv", DataFrame)
println("Loading original data ('hbv_ml.csv') for rule application...")
original_df = CSV.read("hbv_ml.csv", DataFrame)
println("Successfully loaded data.")


# --- 2. Feature Engineering: Add the Biomarker Rule ---
println("Adding the Biomarker Rule as a new feature...")
# Apply the rule to every row of the original data
transform!(original_df, AsTable(All()) => ByRow(apply_biomarker_rule) => :Biomarker_Rule_Result)

# One-hot encode this new categorical feature and add it to our clean dataset
for cat in unique(original_df.Biomarker_Rule_Result)
    new_col_name = "Rule_" * string(cat)
    clean_df[!, Symbol(new_col_name)] = (original_df.Biomarker_Rule_Result .== cat)
end
println("New 'Biomarker_Rule_Result' feature created and encoded.")


# --- 3. Prepare Data for Machine Learning ---
println("\nPreparing final data for ML model...")

# Target for Experiment 2 is 'Expert_Diagnosis'
# We must remove the rows where Expert_Diagnosis is missing
ml_ready_df = filter(row -> !ismissing(row.Expert_Diagnosis), clean_df)
target = ml_ready_df.Expert_Diagnosis

# Features are all columns EXCEPT the two diagnosis columns
features_to_exclude = [:Clinical_Diagnosis, :Expert_Diagnosis]
feature_names = [name for name in names(ml_ready_df) if Symbol(name) ∉ features_to_exclude]
features = Matrix(ml_ready_df[!, feature_names])

println("Target and Feature matrix created successfully.")
println("The model will use $(size(features, 2)) features.")


# --- 4. Split, Train, and Evaluate ---
println("\n--- Starting Model Training and Evaluation ---")
Random.seed!(123)
n_samples = size(features, 1)
train_size = floor(Int, 0.7 * n_samples)
indices = shuffle(1:n_samples)
train_indices = indices[1:train_size]
test_indices = indices[train_size+1:end]

X_train, y_train = features[train_indices, :], target[train_indices]
X_test, y_test = features[test_indices, :], target[test_indices]

println("Data split into $(length(y_train)) training and $(length(y_test)) testing samples.")

model = RandomForestClassifier(n_trees=100)
println("Training the Random Forest model...")
fit!(model, X_train, y_train)
println("Model training complete.")

predictions = predict(model, X_test)

accuracy = sum(predictions .== y_test) / length(y_test)

println("\n-----------------------------------------------------------------------")
println("                  EXPERIMENT 2: FINAL RESULT")
println("-----------------------------------------------------------------------")
@printf("Rule-Enhanced Model Accuracy (predicting the Expert Dx): %.2f%%\n", accuracy * 100)
println("-----------------------------------------------------------------------\n")