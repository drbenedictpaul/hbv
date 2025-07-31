# FILE: inspect_data.jl
# PURPOSE: A quick diagnostic to check the contents of the Expert_Diagnosis column.

using Pkg
Pkg.add("CSV")
Pkg.add("DataFrames")

using CSV
using DataFrames

# Load the data
hbv_data = CSV.read("hbv.csv", DataFrame)

println("--- Inspecting the 'Expert_Diagnosis' Column in hbv.csv ---")
println("This shows all unique values and their counts.\n")

# Group by the Expert_Diagnosis column and count each unique entry
# This will also show us how many are missing (empty).
diagnosis_counts = combine(groupby(hbv_data, :Expert_Diagnosis, sort=true), nrow => :count)

println(diagnosis_counts)