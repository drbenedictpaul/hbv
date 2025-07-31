# ===================================================================
# FILE: run_analysis.jl
# PURPOSE: Main script to calculate and compare diagnostic performance.
# ===================================================================

# --- Setup Environment ---
println("Setting up the environment...")
using Pkg
Pkg.add("DataFrames")
Pkg.add("Printf") # For pretty-printing the final table

using DataFrames
using Printf

# --- Include and Use our Custom Modules ---
include("prepare_data.jl")
include("analyze_performance.jl")
using .DataPreparation
using .PerformanceAnalysis

println("Environment setup complete.")


# --- Main Analysis ---

# Define the path to your data file
data_filepath = "hbv.csv"

# 1. Get the clean data cohort using our module.
# Let's rename it to 'analysis_cohort' to be clear.
analysis_cohort = get_plot_data(data_filepath)


# 2. Apply the lab's rule to create a new prediction column
println("\nApplying the lab's diagnostic rule...")
transform!(analysis_cohort, AsTable(All()) => ByRow(apply_lab_rule) => :Rule_Prediction)
println("Rule applied.")


# 3. Calculate metrics for the original Clinical Diagnosis
println("\nCalculating performance for Clinical Diagnosis...")
clinical_metrics = calculate_metrics(analysis_cohort, :Clinical_Diagnosis, :Expert_Diagnosis)


# 4. Calculate metrics for our new Lab Rule
println("Calculating performance for the Lab Rule...")
lab_rule_metrics = calculate_metrics(analysis_cohort, :Rule_Prediction, :Expert_Diagnosis)


# 5. Print the final, formatted comparison table
println("\n\n--- DIAGNOSTIC PERFORMANCE COMPARISON ---")
println("----------------------------------------------------------")
@printf("%-15s | %-20s | %-15s\n", "Metric", "Clinical Diagnosis", "Proposed Lab Rule")
println("----------------------------------------------------------")
@printf("%-15s | %-20.2f | %-15.2f\n", "Sensitivity", clinical_metrics.sensitivity * 100, lab_rule_metrics.sensitivity * 100)
@printf("%-15s | %-20.2f | %-15.2f\n", "Specificity", clinical_metrics.specificity * 100, lab_rule_metrics.specificity * 100)
@printf("%-15s | %-20.2f | %-15.2f\n", "PPV", clinical_metrics.ppv * 100, lab_rule_metrics.ppv * 100)
@printf("%-15s | %-20.2f | %-15.2f\n", "NPV", clinical_metrics.npv * 100, lab_rule_metrics.npv * 100)
@printf("%-15s | %-20.2f | %-15.2f\n", "Accuracy", clinical_metrics.accuracy * 100, lab_rule_metrics.accuracy * 100)
println("----------------------------------------------------------")
println("(TP, TN, FP, FN) for Lab Rule: ", (lab_rule_metrics.tp, lab_rule_metrics.tn, lab_rule_metrics.fp, lab_rule_metrics.fn))
println("\nAnalysis complete.")