# ===================================================================
# FILE: generate_concordance_plot.jl (Professional Concordance Version)
# PURPOSE: Creates a plot showcasing the diagnostic concordance
#          between the clinical and biomarker diagnoses.
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


# --- Create the Concordance Categories ---
println("Creating the diagnostic concordance categories...")

function get_concordance_category(clinical_dx, biomarker_dx)
    if clinical_dx == "AHB" && biomarker_dx == "AHB"
        return "Concordant: AHB"
    elseif clinical_dx == "CHBAE" && biomarker_dx == "CHBAE"
        return "Concordant: CHBAE"
    elseif clinical_dx == "CHBAE" && biomarker_dx == "AHB"
        return "Discordant (Clinical CHBAE -> Biomarker AHB)"
    elseif clinical_dx == "AHB" && biomarker_dx == "CHBAE"
        return "Discordant (Clinical AHB -> Biomarker CHBAE)"
    else
        return "Other"
    end
end

transform!(analysis_cohort, 
    [:Clinical_Diagnosis, :Biomarker_Rule_Diagnosis] => 
    ByRow((c, b) -> get_concordance_category(c, b)) => 
    :Concordance_Category)

println("Categories created successfully.")


# --- Generate the Concordance Plot ---
println("Generating the diagnostic concordance plot...")

sort!(analysis_cohort, :Concordance_Category, rev=true)

p = Plots.scatter(
    analysis_cohort[!, Symbol("AI (1%GITC)")],
    analysis_cohort[!, Symbol("ARC  IgM Core (S/Co)")],
    group = analysis_cohort[!, :Concordance_Category],
    xlabel = "Avidity Index (AI)",
    ylabel = "IgM Core (S/Co)",
    title = "Diagnostic Concordance: Clinical Impression vs. Biomarker Rule",
    legend = :outertopright,
    markersize = 6,
    alpha = 0.8,
    palette = :tab10
)

vline!(p, [0.46], linestyle = :dash, color = :black, label = "AI Cut-off", linewidth=2)
hline!(p, [8.5], linestyle = :dash, color = :red, label = "IgM Cut-off", linewidth=2)

savefig(p, "diagnostic_concordance_plot.png")

println("\n-----------------------------------------------------------------------")
println("SUCCESS: A new plot has been saved as 'diagnostic_concordance_plot.png'")
println("-----------------------------------------------------------------------\n")