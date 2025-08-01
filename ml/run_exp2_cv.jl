# ===================================================================
# FILE: run_exp2_cv.jl
# PURPOSE: To calculate a robust, cross-validated accuracy for the
#          "Rule-Enhanced" model that predicts the Expert Diagnosis.
# ===================================================================

println("Setting up the ML environment...")
using Pkg
Pkg.add("DataFrames"); Pkg.add("CSV"); Pkg.add("DecisionTree"); Pkg.add("Printf"); Pkg.add("Statistics"); Pkg.add("Random")
using DataFrames, CSV, DecisionTree, Printf, Statistics, Random

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


# --- 1. Load and Prepare Data ---
println("\nLoading data...")
clean_df = CSV.read("hbv_preprocessed.csv", DataFrame)
original_df = CSV.read("hbv_ml.csv", DataFrame)
println("Data loaded.")


# --- 2. Feature Engineering: Add the Biomarker Rule ---
println("Adding the Biomarker Rule as a new feature...")
transform!(original_df, AsTable(All()) => ByRow(apply_biomarker_rule) => :Biomarker_Rule_Result)
for cat in unique(original_df.Biomarker_Rule_Result)
    clean_df[!, "Rule_" * string(cat)] = (original_df.Biomarker_Rule_Result .== cat)
end
println("New feature created and encoded.")


# --- 3. Prepare Final Data for ML ---
println("Preparing final data for ML model...")
ml_ready_df = filter(row -> !ismissing(row.Expert_Diagnosis), clean_df)
target = ml_ready_df.Expert_Diagnosis
features = Matrix(select(ml_ready_df, Not([:Clinical_Diagnosis, :Expert_Diagnosis])))
println("Target and Feature matrix created successfully.")


# --- 4. Perform 10-Fold Cross-Validation (Manually) ---
println("\n--- Starting 10-Fold Cross-Validation for Experiment 2 ---")
n_folds = 10
n_samples = size(features, 1)
Random.seed!(123)
shuffled_indices = shuffle(1:n_samples)
fold_size = floor(Int, n_samples / n_folds)
accuracies = []

for i in 1:n_folds
    println("Running Fold $i of $n_folds...")
    start_idx = (i - 1) * fold_size + 1
    end_idx = i * fold_size
    if i == n_folds; end_idx = n_samples; end
    
    test_indices = shuffled_indices[start_idx:end_idx]
    train_indices = setdiff(shuffled_indices, test_indices)
    
    X_train, y_train = features[train_indices, :], target[train_indices]
    X_test, y_test = features[test_indices, :], target[test_indices]
    
    model = RandomForestClassifier(n_trees=100)
    fit!(model, X_train, y_train)
    
    predictions = predict(model, X_test)
    accuracy = sum(predictions .== y_test) / length(y_test)
    push!(accuracies, accuracy)
end

mean_accuracy = mean(accuracies)
println("Cross-validation complete.")


# --- 5. Report the Final Result ---
println("\n-----------------------------------------------------------------------")
println("          EXPERIMENT 2 (CROSS-VALIDATED): FINAL RESULT")
println("-----------------------------------------------------------------------")
@printf("Mean Accuracy from %d-Fold Cross-Validation: %.2f%%\n", n_folds, mean_accuracy * 100)
rounded_accuracies = round.(accuracies .* 100, digits=2)
println("Individual fold accuracies (%): ", rounded_accuracies)
println("-----------------------------------------------------------------------\n")