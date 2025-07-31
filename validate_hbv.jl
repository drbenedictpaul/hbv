# ===================================================================
# HBV VALIDATION SCRIPT - STEP 1
# ===================================================================

# --- Setup: Load necessary packages ---
# We'll use these to handle data tables and CSV files.
using Pkg
Pkg.add("CSV")
Pkg.add("DataFrames")

using CSV
using DataFrames

println("Step 1: Setup complete. Packages are ready.")


# --- Action: Load the data from your CSV file ---
# This command reads your "hbv.csv" file into a data table called 'hbv_data'.
# Make sure "hbv.csv" is in the same folder as this script.
hbv_data = CSV.read("hbv.csv", DataFrame)


# --- Verification: Confirm the data is loaded ---
println("Data loaded successfully.")
println("Total rows found: ", nrow(hbv_data))
println("Total columns found: ", ncol(hbv_data))

# # We will now print the names of all the columns to verify them
# println("\nColumns in the dataset:")
# println(names(hbv_data))

# println("\nStep 1 is complete.")
println(hbv_data.Expert_Diagnosis)