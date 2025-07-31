# ===================================================================
# HBV DIAGNOSTIC RULE VALIDATION SCRIPT (CORRECTED)
# This script uses the provided "hbv.csv" file.
# ===================================================================

# --- Step A: Setup Environment ---
println("Setting up the environment...")
using Pkg
Pkg.add("CSV")
Pkg.add("DataFrames")
Pkg.add("Plots")
Pkg.add("GR")

using CSV
using DataFrames
using Plots
gr()

println("Environment setup complete.")


# --- Step B: Load and Prepare Data ---
println("\nStep 1: Loading data from 'hbv.csv'...")

hbv_data = CSV.read("hbv.csv", DataFrame)

println("Data loaded successfully.")
println("Found $(nrow(hbv_data)) total rows.")


println("\nStep 2: Creating the validation cohort...")

validation_cohort = filter(row -> 
    !ismissing(row.Expert_Diagnosis) && 
    (row.Expert_Diagnosis == "AHB" || row.Expert_Diagnosis == "CHBAE"),
    hbv_data
)

# Further filter to only include patients with the necessary IgM and AI data.
# CORRECTED LINE: Note the two spaces in "ARC  IgM Core (S/Co)"
plot_data = filter(row -> 
    !ismissing(row[Symbol("AI (1%GITC)")]) && 
    !ismissing(row[Symbol("ARC  IgM Core (S/Co)")]), # <-- TYPO FIXED HERE
    validation_cohort
)

println("Validation cohort created.")
println("Found $(nrow(plot_data)) patients with complete data for plotting.")

println("\nBreakdown of diagnoses in the final plot data:")
final_counts = combine(groupby(plot_data, :Expert_Diagnosis), nrow => :count)
println(final_counts)


# --- Step C: Generate and Save the Plot ---
println("\nStep 3: Generating the 'Four Quadrant' plot...")

# CORRECTED LINE: Note the two spaces in "ARC  IgM Core (S/Co)"
p = scatter(
    plot_data, 
    Symbol("AI (1%GITC)"), 
    Symbol("ARC  IgM Core (S/Co)"), # <-- TYPO FIXED HERE
    group = :Expert_Diagnosis,
    xlabel = "Avidity Index (AI)",
    ylabel = "IgM Core (S/Co)",
    title = "Validation of Diagnostic Rule for HBV",
    legend = :topright,
    markersize = 5,
    alpha = 0.7
)

vline!(p, [0.46], linestyle = :dash, color = :black, label = "AI Cut-off = 0.46", linewidth=2)
hline!(p, [8.5], linestyle = :dash, color = :red, label = "IgM Cut-off = 8.5", linewidth=2)

savefig(p, "hbv_diagnostic_plot.png")

println("\nPlot generation complete!")
println("Please check your folder for the output file: 'hbv_diagnostic_plot.png'")