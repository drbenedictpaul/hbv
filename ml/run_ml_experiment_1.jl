# ===================================================================
# FILE: run_ml_experiment_1.jl (Definitive, Corrected Version)
# PURPOSE: To build and evaluate a model that simulates the
#          initial clinical diagnosis BY LOADING PREPROCESSED DATA.
# ===================================================================

println("Setting up the ML environment...")
using Pkg
Pkg.add("DataFrames"); Pkg.add("CSV"); Pkg.add("DecisionTree"); Pkg.add("Random"); Pkg.add("Printf")
using DataFrames, CSV, DecisionTree, Random, Printf

println("Environment setup complete.")


# --- 1. Load the PREPROCESSED Data ---
println("\nLoading the preprocessed data from 'hbv_preprocessed.csv'...")
clean_df = CSV.read("hbv_preprocessed.csv", DataFrame)
println("Successfully loaded $(nrow(clean_df)) clean patient records.")


# --- 2. Prepare Data for Machine Learning ---
println("\nPreparing final data for ML model...")

# Target for Experiment 1 is 'Clinical_Diagnosis'
target = clean_df.Clinical_Diagnosis

# Features are all columns EXCEPT the two diagnosis columns
features_to_exclude = [:Clinical_Diagnosis, :Expert_Diagnosis]
feature_names = [name for name in names(clean_df) if Symbol(name) ∉ features_to_exclude]
features = Matrix(clean_df[!, feature_names])

println("Target and Feature matrix created successfully.")
println("The model will use $(size(features, 2)) features.")


# --- 3. Split, Train, and Evaluate ---
println("\n--- Starting Model Training and Evaluation ---")
Random.seed!(123)

# --- DEFINITIVE FIX IS HERE ---
n_samples = size(features, 1) # Use size(matrix, 1) for matrices
train_ratio = 0.7
train_size = floor(Int, train_ratio * n_samples)
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
println("                  EXPERIMENT 1: FINAL RESULT")
println("-----------------------------------------------------------------------")
@printf("Baseline Model Accuracy (simulating the clinician): %.2f%%\n", accuracy * 100)
println("-----------------------------------------------------------------------\n")