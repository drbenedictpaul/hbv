# ===================================================================
# FILE: create_preprocessed_file.jl
# PURPOSE: Runs the complete preprocessing workflow and saves the
#          final clean DataFrame to a new CSV file.
# ===================================================================

println("Setting up the environment...")
using Pkg
Pkg.add("DataFrames"); Pkg.add("CSV"); Pkg.add("Statistics")
using DataFrames, CSV, Statistics

# --- Include our preprocessor module ---
# This file must be in the same directory.
include("preprocess_data.jl")
using .DataPreprocessor

println("Environment setup complete.")


# --- 1. Preprocess the Entire Dataset ---
# This single function call runs our entire cleaning plan.
clean_df = preprocess_data("hbv_ml.csv")


# --- 2. Save the Clean Data ---
# Save the resulting DataFrame to a new file.
output_filename = "hbv_preprocessed.csv"
CSV.write(output_filename, clean_df)

println("\n-----------------------------------------------------------------------")
println("SUCCESS: The fully preprocessed data has been saved to:")
println("=> $output_filename")
println("\nThis file is now ready to be used for all machine learning experiments.")
println("-----------------------------------------------------------------------\n")