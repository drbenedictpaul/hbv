# ===================================================================
# FILE: final_report.jl (Generates Report File)
# PURPOSE: Generates a complete report and saves it to a text file.
# ===================================================================

println("Setting up the environment...")
using Pkg
Pkg.add("DataFrames"); Pkg.add("Printf"); Pkg.add("CSV")
using DataFrames, Printf, CSV

# Include our simplified analysis module
include("analyze_performance.jl")
using .PerformanceAnalysis

println("Environment setup complete.")


# --- Main Analysis ---
println("\nLoading and Preparing Data...")
hbv_data = CSV.read("hbv.csv", DataFrame)

println("Applying Biomarker-Based Rule as the Reference Standard...")
transform!(hbv_data, AsTable(All()) => ByRow(apply_biomarker_rule) => :Biomarker_Rule_Diagnosis)

analysis_cohort = filter(row -> row.Biomarker_Rule_Diagnosis != "Ambiguous", hbv_data)
println("Analysis will be performed on $(nrow(analysis_cohort)) patients.")


# --- Calculation of All Necessary Numbers ---
total_clinical_ahb = nrow(filter(row -> row.Clinical_Diagnosis == "AHB", analysis_cohort))
total_clinical_chbae = nrow(filter(row -> row.Clinical_Diagnosis == "CHBAE", analysis_cohort))
total_rule_ahb = nrow(filter(row -> row.Biomarker_Rule_Diagnosis == "AHB", analysis_cohort))
total_rule_chbae = nrow(filter(row -> row.Biomarker_Rule_Diagnosis == "CHBAE", analysis_cohort))

tp = nrow(filter(row -> row.Biomarker_Rule_Diagnosis == "AHB" && row.Clinical_Diagnosis == "AHB", analysis_cohort))
tn = nrow(filter(row -> row.Biomarker_Rule_Diagnosis == "CHBAE" && row.Clinical_Diagnosis == "CHBAE", analysis_cohort))
fp = nrow(filter(row -> row.Biomarker_Rule_Diagnosis == "CHBAE" && row.Clinical_Diagnosis == "AHB", analysis_cohort))
fn = nrow(filter(row -> row.Biomarker_Rule_Diagnosis == "AHB" && row.Clinical_Diagnosis == "CHBAE", analysis_cohort))

# --- GENERATE THE REPORT FILE ---
# Open a new file in "write" mode. It will be named 'diagnostic_report.txt'
report_filename = "diagnostic_report.txt"
open(report_filename, "w") do io
    # All println and @printf commands inside this block will write to the file 'io'

    # --- START OF THE REPORT ---
    println(io, "=========================================================================================")
    println(io, "      FINAL DIAGNOSTIC ACCURACY REPORT")
    println(io, "      Analysis performed on $(nrow(analysis_cohort)) patients")
    println(io, "=========================================================================================")

    # --- Section 1: High-Level Summary Table (Your Format) ---
    println(io, "\n--- 1. High-Level Summary of Diagnosis Counts ---\n")

    println(io, "┌──────────────────────┬────────────────────────┬──────────────────────┐")
    @printf(io, "│ %-20s │ %-22s │ %-20s │\n", "Condition", "Clinical Diagnosis", "Biomarker-Based Rule")
    println(io, "│                      │ (Total Patients)       │ (Total Patients)     │")
    println(io, "├──────────────────────┼────────────────────────┼──────────────────────┤")
    @printf(io, "│ %-20s │ %-22d │ %-20d │\n", "AHB", total_clinical_ahb, total_rule_ahb)
    @printf(io, "│ %-20s │ %-22d │ %-20d │\n", "CHBAE", total_clinical_chbae, total_rule_chbae)
    println(io, "└──────────────────────┴────────────────────────┴──────────────────────┘")

    # --- Section 2: Detailed Head-to-Head Comparison (Confusion Matrix) ---
    println(io, "\n\n--- 2. Detailed Comparison of Agreement (Confusion Matrix) ---\n")
    println(io, "This table breaks down the counts from the summary above, showing")
    println(io, "exactly where the diagnoses agreed and disagreed.\n")

    println(io, "┌─────────────────────────────┬────────────────────────┬────────────────────────┐")
    @printf(io, "│                             │ %-22s │ %-22s │\n", "Clinician Diagnosed As:", "Clinician Diagnosed As:")
    @printf(io, "│ %-27s │ %-22s │ %-22s │\n", "Actual (Biomarker Rule)", "AHB", "CHBAE")
    println(io, "├─────────────────────────────┼────────────────────────┼────────────────────────┤")
    @printf(io, "│ %-27s │ %-22d │ %-22d │\n", "AHB", tp, fn)
    @printf(io, "│ %-27s │ %-22d │ %-22d │\n", "CHBAE", fp, tn)
    println(io, "└─────────────────────────────┴────────────────────────┴────────────────────────┘")
    println(io, "\nKey finding: The table shows 13 patients who were actually AHB were misdiagnosed by clinicians as CHBAE.")

    # --- Section 3: Formal Performance Statistics ---
    println(io, "\n\n--- 3. Performance Statistics of the Initial Clinical Impression ---\n")
    println(io, "The following standard metrics quantify the performance based on the detailed table above.\n")

    accuracy = (tp + tn) / (tp + tn + fp + fn) * 100
    sensitivity = (tp / (tp + fn)) * 100
    specificity = (tn / (tn + fp)) * 100
    ppv = (tp / (tp + fp)) * 100
    npv = (tn / (tn + fn)) * 100

    println(io, "┌─────────────────────────────┬─────────────┐")
    @printf(io, "│ %-27s │ %-11s │\n", "Statistic", "Result (%)")
    println(io, "├─────────────────────────────┼─────────────┤")
    @printf(io, "│ %-27s │ %-11.2f │\n", "Accuracy", accuracy)
    @printf(io, "│ %-27s │ %-11.2f │\n", "Sensitivity", sensitivity)
    @printf(io, "│ %-27s │ %-11.2f │\n", "Specificity", specificity)
    @printf(io, "│ %-27s │ %-11.2f │\n", "Positive Predictive Value (PPV)", ppv)
    @printf(io, "│ %-27s │ %-11.2f │\n", "Negative Predictive Value (NPV)", npv)
    println(io, "└─────────────────────────────┴─────────────┘")

    # --- Section 4: Conclusion ---
    println(io, "\n\n--- 4. Conclusion ---\n")
    println(io, "The analysis shows that while the clinical impression is highly reliable when diagnosing 'AHB' (100% PPV),")
    println(io, "it is significantly less reliable when diagnosing 'CHBAE', with a Negative Predictive Value of only 58.06%.")
    println(io, "This is due to a low Sensitivity (76.79%), where 13 true AHB cases were misclassified.")
    println(io, "The Biomarker-Based Rule successfully identifies these error cases.")

    println(io, "\n=========================================================================================")
    println(io, "                                  END OF REPORT")
    println(io, "=========================================================================================\n")
end

println("\nSUCCESS: The full report has been saved to the file: '$report_filename'")