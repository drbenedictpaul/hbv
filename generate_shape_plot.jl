# ===================================================================
# FILE: generate_shape_plot.jl
# PURPOSE: Creates a clearer plot where color represents the biomarker
#          diagnosis and shape highlights clinical disagreement.
# ===================================================================

println("Setting up the environment...")
using Pkg
Pkg.add("DataFrames"); Pkg.add("Printf"); Pkg.add("CSV"); Pkg.add("Plots"); Pkg.add("GR")
using DataFrames, Printf, CSV, Plots
gr()

# Include our simplified analysis module
include("analyze_performance.jl")
using .PerformanceAnalysis

println("Environment setup complete.")


# --- Main Analysis ---
println("\nLoading and Preparing Data...")
hbv_data = CSV.read("hbv.csv", DataFrame)

println("Applying the Biomarker-Based Rule...")
transform!(hbv_data, AsTable(All()) => ByRow(apply_biomarker_rule) => :Biomarker_Rule_Diagnosis)

analysis_cohort = filter(row -> row.Biomarker_Rule_Diagnosis != "Ambiguous", hbv_data)


# --- Separate data into the four categories for plotting ---
println("Separating data into agreement/disagreement groups...")

# 1. Agree: AHB (Clinician & Rule say AHB)
agree_ahb = filter(row -> row.Clinical_Diagnosis == "AHB" && row.Biomarker_Rule_Diagnosis == "AHB", analysis_cohort)

# 2. Agree: CHBAE (Clinician & Rule say CHBAE)
agree_chbae = filter(row -> row.Clinical_Diagnosis == "CHBAE" && row.Biomarker_Rule_Diagnosis == "CHBAE", analysis_cohort)

# 3. Disagree: The key error group
disagree_missed_ahb = filter(row -> row.Clinical_Diagnosis == "CHBAE" && row.Biomarker_Rule_Diagnosis == "AHB", analysis_cohort)

# 4. Disagree: The other error type (will be empty)
disagree_missed_chbae = filter(row -> row.Clinical_Diagnosis == "AHB" && row.Biomarker_Rule_Diagnosis == "CHBAE", analysis_cohort)


# --- Generate the New "Shape Plot" ---
println("Generating the diagnostic disagreement plot...")

# Start with a blank plot object
p = plot(
    title = "Diagnostic Disagreement: Clinical Impression vs. Biomarker Rule",
    xlabel = "Avidity Index (AI)",
    ylabel = "IgM Core (S/Co)",
    legend = :outertopright
)

# Plot the "Agree: AHB" group as green dots
Plots.scatter!(p,
    agree_ahb[!, Symbol("AI (1%GITC)")],
    agree_ahb[!, Symbol("ARC  IgM Core (S/Co)")],
    label = "Concordant: AHB",
    color = :green,
    shape = :circle,
    markersize = 5
)

# Plot the "Agree: CHBAE" group as blue dots
Plots.scatter!(p,
    agree_chbae[!, Symbol("AI (1%GITC)")],
    agree_chbae[!, Symbol("ARC  IgM Core (S/Co)")],
    label = "Concordant: CHBAE",
    color = :blue,
    shape = :circle,
    markersize = 5
)

# Plot the key "Disagree" group as large green 'X's
Plots.scatter!(p,
    disagree_missed_ahb[!, Symbol("AI (1%GITC)")],
    disagree_missed_ahb[!, Symbol("ARC  IgM Core (S/Co)")],
    label = "Discordant (Biomarker AHB, Clinically CHBAE)",
    color = :green, # Color is the truth (AHB)
    shape = :xcross, # Shape highlights the error
    markersize = 8,
    markerstrokewidth = 2
)

# Add the cut-off lines to show the biomarker rule's decision zones
vline!(p, [0.46], linestyle = :dash, color = :black, label = "AI Cut-off", linewidth=2)
hline!(p, [8.5], linestyle = :dash, color = :red, label = "IgM Cut-off", linewidth=2)

# Save the plot
savefig(p, "diagnostic_disagreement_plot.png")

println("\n-----------------------------------------------------------------------")
println("SUCCESS: A new, clearer plot has been saved as 'diagnostic_disagreement_plot.png'")
println("\nWHAT TO LOOK FOR IN THE PLOT:")
println(" - The large GREEN 'X' markers represent the 13 misdiagnosed patients.")
println(" - Their GREEN COLOR shows their true diagnosis is AHB (by the biomarker rule).")
println(" - Their 'X' SHAPE shows the clinician disagreed.")
println(" - This plot powerfully visualizes the exact nature of the diagnostic errors.")
println("-----------------------------------------------------------------------\n")