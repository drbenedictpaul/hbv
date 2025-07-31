# ===================================================================
# FILE: generate_overlay_plot.jl
# PURPOSE: Creates an intuitive plot that overlays the biomarker
#          classification (squares) on the clinical diagnosis (dots).
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


# --- Separate data by CLINICAL diagnosis for the first layer ---
println("Separating data for plotting...")
clinical_ahb = filter(row -> row.Clinical_Diagnosis == "AHB", analysis_cohort)
clinical_chbae = filter(row -> row.Clinical_Diagnosis == "CHBAE", analysis_cohort)


# --- Generate the Overlay Plot ---
println("Generating the diagnostic overlay plot...")

# Start with a blank plot object
p = plot(
    title = "Biomarker Rule Overlaid on Clinical Diagnosis",
    xlabel = "Avidity Index (AI)",
    ylabel = "IgM Core (S/Co)",
    legend = :outertopright
)

# 1. Plot the Clinical Diagnoses as Dots (the first layer)
Plots.scatter!(p,
    clinical_ahb[!, Symbol("AI (1%GITC)")],
    clinical_ahb[!, Symbol("ARC  IgM Core (S/Co)")],
    label = "Clinical Diagnosis: AHB",
    color = :green,
    shape = :circle,
    markersize = 6
)

Plots.scatter!(p,
    clinical_chbae[!, Symbol("AI (1%GITC)")],
    clinical_chbae[!, Symbol("ARC  IgM Core (S/Co)")],
    label = "Clinical Diagnosis: CHBAE",
    color = :red,
    shape = :circle,
    markersize = 6
)


# 2. Overlay the Biomarker Rule as Open Squares (the second layer)
# We plot ALL patients again, this time colored by the rule and using a square shape.
# 'markerstrokecolor' and 'fillalpha=0' make the squares hollow so we can see the dot inside.

# Biomarker AHB cases
biomarker_ahb = filter(row -> row.Biomarker_Rule_Diagnosis == "AHB", analysis_cohort)
Plots.scatter!(p,
    biomarker_ahb[!, Symbol("AI (1%GITC)")],
    biomarker_ahb[!, Symbol("ARC  IgM Core (S/Co)")],
    label = "Biomarker Rule: AHB",
    shape = :square,
    markersize = 10,
    markerstrokecolor = :purple,
    markerstrokewidth = 2,
    fillalpha = 0 # Hollow square
)

# Biomarker CHBAE cases
biomarker_chbae = filter(row -> row.Biomarker_Rule_Diagnosis == "CHBAE", analysis_cohort)
Plots.scatter!(p,
    biomarker_chbae[!, Symbol("AI (1%GITC)")],
    biomarker_chbae[!, Symbol("ARC  IgM Core (S/Co)")],
    label = "Biomarker Rule: CHBAE",
    shape = :square,
    markersize = 10,
    markerstrokecolor = :blue,
    markerstrokewidth = 2,
    fillalpha = 0 # Hollow square
)


# Add the cut-off lines for context
vline!(p, [0.46], linestyle = :dash, color = :black, label = "", linewidth=1.5)
hline!(p, [8.5], linestyle = :dash, color = :black, label = "", linewidth=1.5)


# Save the plot
savefig(p, "diagnostic_overlay_plot.png")

println("\n-----------------------------------------------------------------------")
println("SUCCESS: Your new plot has been saved as 'diagnostic_overlay_plot.png'")
println("\nWHAT TO LOOK FOR IN THE PLOT:")
println(" - A RED DOT inside a PURPLE SQUARE represents a misdiagnosed case.")
println("   (Clinician said CHBAE, but the rule proves it's AHB).")
println(" - A GREEN DOT inside a PURPLE SQUARE represents agreement on AHB.")
println(" - A RED DOT inside a BLUE SQUARE represents agreement on CHBAE.")
println("-----------------------------------------------------------------------\n")