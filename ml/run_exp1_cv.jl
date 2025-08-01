# ===================================================================
# FILE: run_exp1_cv.jl (Definitive, Manual Cross-Validation)
# PURPOSE: To calculate a robust, cross-validated accuracy by
#          manually implementing the cross-validation loop. This
#          is the most robust and reliable method.
# ===================================================================

println("Setting up the ML environment...")
using Pkg
Pkg.add("DataFrames"); Pkg.add("CSV"); Pkg.add("DecisionTree"); Pkg.add("Printf"); Pkg.add("Statistics"); Pkg.add("Random")
using DataFrames, CSV, DecisionTree, Printf, Statistics, Random

println("Environment setup complete.")


# --- 1. Load the Preprocessed Data ---
println("\nLoading the preprocessed data from 'hbv_preprocessed.csv'...")
clean_df = CSV.read("hbv_preprocessed.csv", DataFrame)
println("Successfully loaded $(nrow(clean_df)) clean patient records.")


# --- 2. Prepare Data for Machine Learning ---
println("Preparing final data for ML model...")
target = clean_df.Clinical_Diagnosis
features = Matrix(select(clean_df, Not([:Clinical_Diagnosis, :Expert_Diagnosis])))
println("Target and Feature matrix created successfully.")


# --- 3. Perform 10-Fold Cross-Validation (Manually) ---
println("\n--- Starting 10-Fold Cross-Validation for Experiment 1 ---")

n_folds = 10
n_samples = size(features, 1)

# Shuffle the indices of the data once
Random.seed!(123)
shuffled_indices = shuffle(1:n_samples)

# Determine the size of each fold
fold_size = floor(Int, n_samples / n_folds)
accuracies = [] # An array to store the accuracy of each fold

for i in 1:n_folds
    println("Running Fold $i of $n_folds...")
    
    # Determine the start and end indices for the current TEST fold
    start_idx = (i - 1) * fold_size + 1
    end_idx = i * fold_size
    if i == n_folds # Ensure the last fold includes all remaining samples
        end_idx = n_samples
    end
    
    # Define the indices for the test set for this fold
    test_indices = shuffled_indices[start_idx:end_idx]
    
    # The training set is everything ELSE
    train_indices = setdiff(shuffled_indices, test_indices)
    
    # Create the data splits for this specific fold
    X_train, y_train = features[train_indices, :], target[train_indices]
    X_test, y_test = features[test_indices, :], target[test_indices]
    
    # Train the model on this fold's training data
    model = RandomForestClassifier(n_trees=100)
    fit!(model, X_train, y_train)
    
    # Make predictions and calculate accuracy for this fold
    predictions = predict(model, X_test)
    accuracy = sum(predictions .== y_test) / length(y_test)
    push!(accuracies, accuracy)
end

mean_accuracy = mean(accuracies)
println("Cross-validation complete.")


# --- 4. Report the Final Result ---
println("\n-----------------------------------------------------------------------")
println("          EXPERIMENT 1 (CROSS-VALIDATED): FINAL RESULT")
println("-----------------------------------------------------------------------")
@printf("Mean Accuracy from %d-Fold Cross-Validation: %.2f%%\n", n_folds, mean_accuracy * 100)
# Round the individual accuracies for cleaner printing
rounded_accuracies = round.(accuracies .* 100, digits=2)
println("Individual fold accuracies (%): ", rounded_accuracies)
println("-----------------------------------------------------------------------\n")