# ===================================================================
# FILE: generate_plot.jl
# PURPOSE: Main script to generate and save the HBV diagnostic plot.
# ===================================================================

# --- Setup Environment ---
println("Setting up the environment...")
using Pkg
Pkg.add("Plots")
Pkg.add("GR")
Pkg.add("DataFrames")

using Plots
using DataFrames
gr() # Tell Plots to use the GR backend. No 'using GR' needed.

# --- Include and Use our Data Module ---
include("prepare_data.jl")
using .DataPreparation

println("Environment setup complete.")


# --- Main Analysis ---

data_filepath = "hbv.csv"
plot_data = get_plot_data(data_filepath)

println("\nBreakdown of diagnoses in the final plot data:")
final_counts = combine(groupby(plot_data, :Expert_Diagnosis), nrow => :count)
println(final_counts)

println("\nStep 3: Generating the 'Four Quadrant' plot...")

# --- Plot Generation ---
# CORRECTED: We now explicitly call Plots.scatter
p = Plots.scatter(
    plot_data[!, Symbol("AI (1%GITC)")],
    plot_data[!, Symbol("ARC  IgM Core (S/Co)")],
    group = plot_data[!, :Expert_Diagnosis],
    xlabel = "Avidity Index (AI)",
    ylabel = "IgM Core (S/Co)",
    title = "Validation of Diagnostic Rule for HBV",
    legend = :topright,
    markersize = 5,
    alpha = 0.7
)

# vline! and hline! modify the plot 'p', so they don't need the prefix.
vline!(p, [0.46], linestyle = :dash, color = :black, label = "AI Cut-off = 0.46", linewidth=2)
hline!(p, [8.5], linestyle = :dash, color = :red, label = "IgM Cut-off = 8.5", linewidth=2)

# savefig is also a function from Plots
Plots.savefig(p, "hbv_diagnostic_plot.png")

println("\nPlot generation complete!")
println("Please check your folder for the output file: 'hbv_diagnostic_plot.png'")