# ===================================================================
# FILE: analyze_performance.jl
# PURPOSE: Contains the logic for the biomarker-based rule.
# ===================================================================
module PerformanceAnalysis

export apply_biomarker_rule

using DataFrames

function apply_biomarker_rule(row)
    # Get the values, using Symbol() for columns with special chars/spaces
    igm = row[Symbol("ARC  IgM Core (S/Co)")]
    ai = row[Symbol("AI (1%GITC)")]

    if ismissing(igm) || ismissing(ai)
        return "Ambiguous"
    end

    if igm > 8.5 && ai < 0.46
        return "AHB"
    elseif igm < 8.5 && ai > 0.46
        return "CHBAE"
    else
        # This is the "grey zone"
        return "Ambiguous"
    end
end

end # end module