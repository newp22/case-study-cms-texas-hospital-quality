/*
CMS Texas Hospital Quality Power Query M Code

To reproduce, create a separate Excel query for each shared definition in the order below. In the Excel Advanced Editor, copy only between the expression beginning with "let" and ending with the final expression after "in".

Note that the three raw source queries contain local file paths. Replace those paths with the location of the downloaded CMS files.
*/

section CMS_Texas_Hospital_Quality_Power_Query;

shared Hospital_Raw = 
let
    Source =
        Csv.Document(
            File.Contents(
                "C:\Users\vucli\OneDrive\Documents\Projects\data-analytics\case-study-tx-hospital-quality\cms-data-released-05132026-modified-04282026\Hospital_General_Information.csv"
            ),
            [
                Delimiter = ",",
                Encoding = 65001,
                QuoteStyle = QuoteStyle.Csv
            ]
        ),

    PromotedHeaders =
        Table.PromoteHeaders(
            Source,
            [PromoteAllScalars = true]
        )
in
    PromotedHeaders;

shared Hospital_Clean =
let
    Source =
        Hospital_Raw,

    KeepRelevantColumns =
        Table.SelectColumns(
            Source,
            {
                "Facility ID",
                "Facility Name",
                "Address",
                "City/Town",
                "State",
                "ZIP Code",
                "County/Parish",
                "Telephone Number",
                "Hospital Type",
                "Hospital Ownership",
                "Emergency Services",
                "Hospital overall rating",
                "Hospital overall rating footnote"
            },
            MissingField.UseNull
        ),

    SetTextTypes =
        Table.TransformColumnTypes(
            KeepRelevantColumns,
            {
                {"Facility ID", type text},
                {"Facility Name", type text},
                {"Address", type text},
                {"City/Town", type text},
                {"State", type text},
                {"ZIP Code", type text},
                {"County/Parish", type text},
                {"Telephone Number", type text},
                {"Hospital Type", type text},
                {"Hospital Ownership", type text},
                {"Emergency Services", type text},
                {"Hospital overall rating", type text},
                {"Hospital overall rating footnote", type text}
            }
        ),

    CleanText =
        Table.TransformColumns(
            SetTextTypes,
            {
                {
                    "Facility ID",
                    each if _ = null then null else Text.Trim(_),
                    type text
                },
                {
                    "Facility Name",
                    each if _ = null then null else Text.Trim(_),
                    type text
                },
                {
                    "Address",
                    each if _ = null then null else Text.Trim(_),
                    type text
                },
                {
                    "City/Town",
                    each if _ = null then null else Text.Trim(_),
                    type text
                },
                {
                    "State",
                    each
                        if _ = null
                        then null
                        else Text.Upper(Text.Trim(_)),
                    type text
                },
                {
                    "ZIP Code",
                    each if _ = null then null else Text.Trim(_),
                    type text
                },
                {
                    "County/Parish",
                    each if _ = null then null else Text.Trim(_),
                    type text
                },
                {
                    "Hospital Type",
                    each if _ = null then null else Text.Trim(_),
                    type text
                },
                {
                    "Hospital Ownership",
                    each if _ = null then null else Text.Trim(_),
                    type text
                }
            }
        ),

    FilterTexas =
        Table.SelectRows(
            CleanText,
            each [State] = "TX"
        ),

    FilterAcuteCare =
        Table.SelectRows(
            FilterTexas,
            each [Hospital Type] = "Acute Care Hospitals"
        ),

    AddNumericOverallRating =
        Table.AddColumn(
            FilterAcuteCare,
            "Overall_Rating",
            each
                try
                    Int64.From(
                        Number.FromText(
                            [Hospital overall rating]
                        )
                    )
                otherwise
                    null,
            Int64.Type
        ),

    RenameColumns =
        Table.RenameColumns(
            AddNumericOverallRating,
            {
                {"Facility ID", "Facility_ID"},
                {"Facility Name", "Facility_Name"},
                {"City/Town", "City"},
                {"ZIP Code", "ZIP_Code"},
                {"County/Parish", "County"},
                {"Telephone Number", "Telephone_Number"},
                {"Hospital Type", "Hospital_Type"},
                {"Hospital Ownership", "Hospital_Ownership"},
                {"Emergency Services", "Emergency_Services"},
                {
                    "Hospital overall rating",
                    "Overall_Rating_Raw"
                },
                {
                    "Hospital overall rating footnote",
                    "Overall_Rating_Footnote"
                }
            }
        ),

    ReorderColumns =
        Table.ReorderColumns(
            RenameColumns,
            {
                "Facility_ID",
                "Facility_Name",
                "Address",
                "City",
                "State",
                "ZIP_Code",
                "County",
                "Telephone_Number",
                "Hospital_Type",
                "Hospital_Ownership",
                "Emergency_Services",
                "Overall_Rating",
                "Overall_Rating_Raw",
                "Overall_Rating_Footnote"
            }
        )
in
    ReorderColumns;

shared QA_Hospital_Duplicates =
let
    Source =
        Hospital_Clean,

    GroupByFacility =
        Table.Group(
            Source,
            {"Facility_ID"},
            {
                {
                    "Row_Count",
                    each Table.RowCount(_),
                    Int64.Type
                }
            }
        ),

    DuplicateFacilities =
        Table.SelectRows(
            GroupByFacility,
            each [Row_Count] > 1
        )
in
    DuplicateFacilities;

shared HCAHPS_Raw =
let
    Source =
        Csv.Document(
            File.Contents(
                "C:\Users\vucli\OneDrive\Documents\Projects\data-analytics\case-study-tx-hospital-quality\cms-data-released-05132026-modified-04282026\HCAHPS-Hospital.csv"
            ),
            [
                Delimiter = ",",
                Encoding = 65001,
                QuoteStyle = QuoteStyle.Csv
            ]
        ),

    PromotedHeaders =
        Table.PromoteHeaders(
            Source,
            [PromoteAllScalars = true]
        )
in
    PromotedHeaders;

shared HCAHPS_Selected_Long =
let
    Source =
        HCAHPS_Raw,

    SelectedMeasureIDs =
        {
            "H_COMP_1_A_P",
            "H_COMP_2_A_P",
            "H_COMP_5_A_P",
            "H_COMP_6_Y_P",
            "H_HSP_RATING_9_10",
            "H_RECMND_DY"
        },

    KeepRelevantColumns =
        Table.SelectColumns(
            Source,
            {
                "Facility ID",
                "Facility Name",
                "State",
                "HCAHPS Measure ID",
                "HCAHPS Question",
                "HCAHPS Answer Description",
                "HCAHPS Answer Percent",
                "HCAHPS Answer Percent Footnote",
                "Number of Completed Surveys",
                "Number of Completed Surveys Footnote",
                "Survey Response Rate Percent",
                "Survey Response Rate Percent Footnote",
                "Start Date",
                "End Date"
            },
            MissingField.UseNull
        ),

    SetTextTypes =
        Table.TransformColumnTypes(
            KeepRelevantColumns,
            {
                {"Facility ID", type text},
                {"Facility Name", type text},
                {"State", type text},
                {"HCAHPS Measure ID", type text},
                {"HCAHPS Question", type text},
                {"HCAHPS Answer Description", type text},
                {"HCAHPS Answer Percent", type text},
                {"HCAHPS Answer Percent Footnote", type text},
                {"Number of Completed Surveys", type text},
                {
                    "Number of Completed Surveys Footnote",
                    type text
                },
                {"Survey Response Rate Percent", type text},
                {
                    "Survey Response Rate Percent Footnote",
                    type text
                },
                {"Start Date", type text},
                {"End Date", type text}
            }
        ),

    CleanText =
        Table.TransformColumns(
            SetTextTypes,
            {
                {
                    "Facility ID",
                    each if _ = null then null else Text.Trim(_),
                    type text
                },
                {
                    "Facility Name",
                    each if _ = null then null else Text.Trim(_),
                    type text
                },
                {
                    "State",
                    each
                        if _ = null
                        then null
                        else Text.Upper(Text.Trim(_)),
                    type text
                },
                {
                    "HCAHPS Measure ID",
                    each if _ = null then null else Text.Trim(_),
                    type text
                }
            }
        ),

    FilterTexas =
        Table.SelectRows(
            CleanText,
            each [State] = "TX"
        ),

    FilterSelectedMeasures =
        Table.SelectRows(
            FilterTexas,
            each
                List.Contains(
                    SelectedMeasureIDs,
                    [HCAHPS Measure ID]
                )
        ),

    AddNumericAnswerPercent =
        Table.AddColumn(
            FilterSelectedMeasures,
            "HCAHPS_Value_Pct",
            each
                try
                    Number.FromText(
                        [HCAHPS Answer Percent]
                    )
                otherwise
                    null,
            type nullable number
        ),

    AddNumericResponseRate =
        Table.AddColumn(
            AddNumericAnswerPercent,
            "Survey_Response_Rate_Pct",
            each
                try
                    Number.FromText(
                        [Survey Response Rate Percent]
                    )
                otherwise
                    null,
            type nullable number
        ),

    AddStartDate =
        Table.AddColumn(
            AddNumericResponseRate,
            "HCAHPS_Start_Date",
            each
                try Date.From([Start Date])
                otherwise null,
            type nullable date
        ),

    AddEndDate =
        Table.AddColumn(
            AddStartDate,
            "HCAHPS_End_Date",
            each
                try Date.From([End Date])
                otherwise null,
            type nullable date
        ),

    EligibleHospitalIDs =
        Table.SelectColumns(
            Hospital_Clean,
            {"Facility_ID"}
        ),

    KeepEligibleHospitals =
        Table.NestedJoin(
            AddEndDate,
            {"Facility ID"},
            EligibleHospitalIDs,
            {"Facility_ID"},
            "EligibleHospital",
            JoinKind.Inner
        ),

    RemoveJoinColumn =
        Table.RemoveColumns(
            KeepEligibleHospitals,
            {"EligibleHospital"}
        ),

    RenameFacilityID =
        Table.RenameColumns(
            RemoveJoinColumn,
            {
                {"Facility ID", "Facility_ID"}
            }
        )
in
    RenameFacilityID;

shared QA_HCAHPS_Duplicates =
let
    Source =
        HCAHPS_Selected_Long,

    GroupByFacilityAndMeasure =
        Table.Group(
            Source,
            {
                "Facility_ID",
                "HCAHPS Measure ID"
            },
            {
                {
                    "Row_Count",
                    each Table.RowCount(_),
                    Int64.Type
                }
            }
        ),

    DuplicateMeasureRows =
        Table.SelectRows(
            GroupByFacilityAndMeasure,
            each [Row_Count] > 1
        )
in
    DuplicateMeasureRows;

shared QA_HCAHPS_Metadata_Inconsistencies =
let
    Source =
        HCAHPS_Selected_Long,

    GroupByHospital =
        Table.Group(
            Source,
            {"Facility_ID"},
            {
                {
                    "Completed_Survey_Value_Count",
                    each
                        List.Count(
                            List.Distinct(
                                List.RemoveNulls(
                                    [Number of Completed Surveys]
                                )
                            )
                        ),
                    Int64.Type
                },
                {
                    "Response_Rate_Value_Count",
                    each
                        List.Count(
                            List.Distinct(
                                List.RemoveNulls(
                                    [Survey_Response_Rate_Pct]
                                )
                            )
                        ),
                    Int64.Type
                },
                {
                    "Start_Date_Value_Count",
                    each
                        List.Count(
                            List.Distinct(
                                List.RemoveNulls(
                                    [HCAHPS_Start_Date]
                                )
                            )
                        ),
                    Int64.Type
                },
                {
                    "End_Date_Value_Count",
                    each
                        List.Count(
                            List.Distinct(
                                List.RemoveNulls(
                                    [HCAHPS_End_Date]
                                )
                            )
                        ),
                    Int64.Type
                }
            }
        ),

    InconsistentHospitals =
        Table.SelectRows(
            GroupByHospital,
            each
                [Completed_Survey_Value_Count] > 1
                or [Response_Rate_Value_Count] > 1
                or [Start_Date_Value_Count] > 1
                or [End_Date_Value_Count] > 1
        )
in
    InconsistentHospitals;

shared HCAHPS_Clean =
let
    Source =
        HCAHPS_Selected_Long,
    SelectedMeasureIDs =
        {
            "H_COMP_1_A_P",
            "H_COMP_2_A_P",
            "H_COMP_5_A_P",
            "H_COMP_6_Y_P",
            "H_HSP_RATING_9_10",
            "H_RECMND_DY"
        },

    PivotInput =
        Table.SelectColumns(
            Source,
            {
                "Facility_ID",
                "HCAHPS Measure ID",
                "HCAHPS_Value_Pct"
            }
        ),

    PivotMeasures =
        Table.Pivot(
            PivotInput,
            SelectedMeasureIDs,
            "HCAHPS Measure ID",
            "HCAHPS_Value_Pct"
        ),

    HospitalMetadata =
        Table.Group(
            Source,
            {"Facility_ID"},
            {
                {
                    "Completed_Surveys_Raw",
                    each
                        try
                            List.First(
                                List.RemoveNulls(
                                    [Number of Completed Surveys]
                                )
                            )
                        otherwise
                            null,
                    type nullable text
                },
                {
                    "Survey_Response_Rate_Pct",
                    each
                        try
                            List.First(
                                List.RemoveNulls(
                                    [Survey_Response_Rate_Pct]
                                )
                            )
                        otherwise
                            null,
                    type nullable number
                },
                {
                    "HCAHPS_Start_Date",
                    each
                        try
                            List.First(
                                List.RemoveNulls(
                                    [HCAHPS_Start_Date]
                                )
                            )
                        otherwise
                            null,
                    type nullable date
                },
                {
                    "HCAHPS_End_Date",
                    each
                        try
                            List.First(
                                List.RemoveNulls(
                                    [HCAHPS_End_Date]
                                )
                            )
                        otherwise
                            null,
                    type nullable date
                }
            }
        ),

    MergeMetadata =
        Table.NestedJoin(
            PivotMeasures,
            {"Facility_ID"},
            HospitalMetadata,
            {"Facility_ID"},
            "Metadata",
            JoinKind.LeftOuter
        ),

    ExpandMetadata =
        Table.ExpandTableColumn(
            MergeMetadata,
            "Metadata",
            {
                "Completed_Surveys_Raw",
                "Survey_Response_Rate_Pct",
                "HCAHPS_Start_Date",
                "HCAHPS_End_Date"
            },
            {
                "Completed_Surveys_Raw",
                "Survey_Response_Rate_Pct",
                "HCAHPS_Start_Date",
                "HCAHPS_End_Date"
            }
        ),

    RenameMeasureColumns =
        Table.RenameColumns(
            ExpandMetadata,
            {
                {
                    "H_COMP_1_A_P",
                    "Nurse_Communication_Pct"
                },
                {
                    "H_COMP_2_A_P",
                    "Doctor_Communication_Pct"
                },
                {
                    "H_COMP_5_A_P",
                    "Medicine_Communication_Pct"
                },
                {
                    "H_COMP_6_Y_P",
                    "Discharge_Info_Pct"
                },
                {
                    "H_HSP_RATING_9_10",
                    "Hospital_Rating_9_10_Pct"
                },
                {
                    "H_RECMND_DY",
                    "Definitely_Recommend_Pct"
                }
            },
            MissingField.Ignore
        ),

    ReorderColumns =
        Table.ReorderColumns(
            RenameMeasureColumns,
            {
                "Facility_ID",
                "Nurse_Communication_Pct",
                "Doctor_Communication_Pct",
                "Medicine_Communication_Pct",
                "Discharge_Info_Pct",
                "Hospital_Rating_9_10_Pct",
                "Definitely_Recommend_Pct",
                "Completed_Surveys_Raw",
                "Survey_Response_Rate_Pct",
                "HCAHPS_Start_Date",
                "HCAHPS_End_Date"
            },
            MissingField.Ignore
        )
in
    ReorderColumns;

shared Unplanned_Raw =
let
    Source =
        Csv.Document(
            File.Contents(
                "C:\Users\vucli\OneDrive\Documents\Projects\data-analytics\case-study-tx-hospital-quality\cms-data-released-05132026-modified-04282026\Unplanned_Hospital_Visits-Hospital.csv"
            ),
            [
                Delimiter = ",",
                Encoding = 65001,
                QuoteStyle = QuoteStyle.Csv
            ]
        ),

    PromotedHeaders =
        Table.PromoteHeaders(
            Source,
            [PromoteAllScalars = true]
        )
in
    PromotedHeaders;

shared Readmission_Selected_Long =
let
    Source =
        Unplanned_Raw,

    KeepRelevantColumns =
        Table.SelectColumns(
            Source,
            {
                "Facility ID",
                "Facility Name",
                "State",
                "Measure ID",
                "Measure Name",
                "Compared to National",
                "Denominator",
                "Score",
                "Lower Estimate",
                "Higher Estimate",
                "Number of Patients",
                "Number of Patients Returned",
                "Footnote",
                "Start Date",
                "End Date"
            },
            MissingField.UseNull
        ),

    SetTextTypes =
        Table.TransformColumnTypes(
            KeepRelevantColumns,
            {
                {"Facility ID", type text},
                {"Facility Name", type text},
                {"State", type text},
                {"Measure ID", type text},
                {"Measure Name", type text},
                {"Compared to National", type text},
                {"Denominator", type text},
                {"Score", type text},
                {"Lower Estimate", type text},
                {"Higher Estimate", type text},
                {"Number of Patients", type text},
                {"Number of Patients Returned", type text},
                {"Footnote", type text},
                {"Start Date", type text},
                {"End Date", type text}
            }
        ),

    CleanText =
        Table.TransformColumns(
            SetTextTypes,
            {
                {
                    "Facility ID",
                    each if _ = null then null else Text.Trim(_),
                    type text
                },
                {
                    "Facility Name",
                    each if _ = null then null else Text.Trim(_),
                    type text
                },
                {
                    "State",
                    each
                        if _ = null
                        then null
                        else Text.Upper(Text.Trim(_)),
                    type text
                },
                {
                    "Measure ID",
                    each if _ = null then null else Text.Trim(_),
                    type text
                },
                {
                    "Compared to National",
                    each if _ = null then null else Text.Trim(_),
                    type text
                }
            }
        ),

    FilterTexas =
        Table.SelectRows(
            CleanText,
            each [State] = "TX"
        ),

    FilterHybridHWR =
        Table.SelectRows(FilterTexas, each [Measure ID] = "Hybrid_HWR"),

    AddNumericScore =
        Table.AddColumn(
            FilterHybridHWR,
            "Readmission_Rate_Pct",
            each
                try Number.FromText([Score])
                otherwise null,
            type nullable number
        ),

    AddNumericDenominator =
        Table.AddColumn(
            AddNumericScore,
            "Readmission_Denominator",
            each
                try Number.FromText([Denominator])
                otherwise null,
            type nullable number
        ),

    AddNumericLowerEstimate =
        Table.AddColumn(
            AddNumericDenominator,
            "Readmission_Lower_Estimate",
            each
                try Number.FromText([Lower Estimate])
                otherwise null,
            type nullable number
        ),

    AddNumericHigherEstimate =
        Table.AddColumn(
            AddNumericLowerEstimate,
            "Readmission_Higher_Estimate",
            each
                try Number.FromText([Higher Estimate])
                otherwise null,
            type nullable number
        ),

    AddStartDate =
        Table.AddColumn(
            AddNumericHigherEstimate,
            "Readmission_Start_Date",
            each
                try Date.From([Start Date])
                otherwise null,
            type nullable date
        ),

    AddEndDate =
        Table.AddColumn(
            AddStartDate,
            "Readmission_End_Date",
            each
                try Date.From([End Date])
                otherwise null,
            type nullable date
        ),

    NormalizeComparison =
        Table.AddColumn(
            AddEndDate,
            "Readmission_Comparison",
            each
                let
                    ComparisonText =
                        if [Compared to National] = null
                        then ""
                        else
                            Text.Lower(
                                [Compared to National]
                            )
                in
                    if Text.Contains(
                        ComparisonText,
                        "worse"
                    )
                    then "Worse"
                    else if Text.Contains(
                        ComparisonText,
                        "better"
                    )
                    then "Better"
                    else if
                        Text.Contains(
                            ComparisonText,
                            "no different"
                        )
                        or Text.Contains(
                            ComparisonText,
                            "same"
                        )
                    then "No Different"
                    else null,
            type nullable text
        ),

    EligibleHospitalIDs =
        Table.SelectColumns(
            Hospital_Clean,
            {"Facility_ID"}
        ),

    KeepEligibleHospitals =
        Table.NestedJoin(
            NormalizeComparison,
            {"Facility ID"},
            EligibleHospitalIDs,
            {"Facility_ID"},
            "EligibleHospital",
            JoinKind.Inner
        ),

    RemoveJoinColumn =
        Table.RemoveColumns(
            KeepEligibleHospitals,
            {"EligibleHospital"}
        ),

    RenameFacilityID =
        Table.RenameColumns(
            RemoveJoinColumn,
            {
                {"Facility ID", "Facility_ID"}
            }
        )
in
    RenameFacilityID;

shared QA_Readmission_Duplicates =
let
    Source =
        Readmission_Selected_Long,

    GroupByFacilityAndMeasure =
        Table.Group(
            Source,
            {
                "Facility_ID",
                "Measure ID"
            },
            {
                {
                    "Row_Count",
                    each Table.RowCount(_),
                    Int64.Type
                }
            }
        ),

    DuplicateMeasureRows =
        Table.SelectRows(
            GroupByFacilityAndMeasure,
            each [Row_Count] > 1
        )
in
    DuplicateMeasureRows;

shared Readmission_Clean =
let
    Source =
        Readmission_Selected_Long,

    KeepFinalColumns =
        Table.SelectColumns(
            Source,
            {
                "Facility_ID",
                "Readmission_Rate_Pct",
                "Readmission_Comparison",
                "Readmission_Denominator",
                "Readmission_Lower_Estimate",
                "Readmission_Higher_Estimate",
                "Footnote",
                "Readmission_Start_Date",
                "Readmission_End_Date"
            }
        ),

    RenameFootnote =
        Table.RenameColumns(
            KeepFinalColumns,
            {
                {
                    "Footnote",
                    "Readmission_Footnote"
                }
            }
        )
in
    RenameFootnote;

shared Analysis_Model =
let
    Source =
        Hospital_Clean,

    MergeHCAHPS =
        Table.NestedJoin(
            Source,
            {"Facility_ID"},
            HCAHPS_Clean,
            {"Facility_ID"},
            "HCAHPS",
            JoinKind.LeftOuter
        ),

    ExpandHCAHPS =
        Table.ExpandTableColumn(
            MergeHCAHPS,
            "HCAHPS",
            {
                "Nurse_Communication_Pct",
                "Doctor_Communication_Pct",
                "Medicine_Communication_Pct",
                "Discharge_Info_Pct",
                "Hospital_Rating_9_10_Pct",
                "Definitely_Recommend_Pct",
                "Completed_Surveys_Raw",
                "Survey_Response_Rate_Pct",
                "HCAHPS_Start_Date",
                "HCAHPS_End_Date"
            },
            {
                "Nurse_Communication_Pct",
                "Doctor_Communication_Pct",
                "Medicine_Communication_Pct",
                "Discharge_Info_Pct",
                "Hospital_Rating_9_10_Pct",
                "Definitely_Recommend_Pct",
                "Completed_Surveys_Raw",
                "Survey_Response_Rate_Pct",
                "HCAHPS_Start_Date",
                "HCAHPS_End_Date"
            }
        ),

    MergeReadmission =
        Table.NestedJoin(
            ExpandHCAHPS,
            {"Facility_ID"},
            Readmission_Clean,
            {"Facility_ID"},
            "Readmission",
            JoinKind.LeftOuter
        ),

    ExpandReadmission =
        Table.ExpandTableColumn(
            MergeReadmission,
            "Readmission",
            {
                "Readmission_Rate_Pct",
                "Readmission_Comparison",
                "Readmission_Denominator",
                "Readmission_Lower_Estimate",
                "Readmission_Higher_Estimate",
                "Readmission_Footnote",
                "Readmission_Start_Date",
                "Readmission_End_Date"
            },
            {
                "Readmission_Rate_Pct",
                "Readmission_Comparison",
                "Readmission_Denominator",
                "Readmission_Lower_Estimate",
                "Readmission_Higher_Estimate",
                "Readmission_Footnote",
                "Readmission_Start_Date",
                "Readmission_End_Date"
            }
        ),

    AddOverallRatingAvailability =
        Table.AddColumn(
            ExpandReadmission,
            "Overall_Rating_Available",
            each [Overall_Rating] <> null,
            type logical
        ),

    AddHCAHPSAvailability =
        Table.AddColumn(
            AddOverallRatingAvailability,
            "HCAHPS_Available",
            each
                [Nurse_Communication_Pct] <> null
                or [Doctor_Communication_Pct] <> null
                or [Medicine_Communication_Pct] <> null
                or [Discharge_Info_Pct] <> null
                or [Hospital_Rating_9_10_Pct] <> null
                or [Definitely_Recommend_Pct] <> null,
            type logical
        ),

    AddReadmissionAvailability =
        Table.AddColumn(
            AddHCAHPSAvailability,
            "Readmission_Available",
            each [Readmission_Rate_Pct] <> null,
            type logical
        )
in
    AddReadmissionAvailability;

shared QA_Hospitals_Without_HCAHPS =
let
    Source =
        Table.NestedJoin(
            Hospital_Clean,
            {"Facility_ID"},
            HCAHPS_Clean,
            {"Facility_ID"},
            "HCAHPSMatch",
            JoinKind.LeftAnti
        )
in
    Source;

shared QA_Hospitals_Without_Readmission =
let
    Source =
        Table.NestedJoin(
            Hospital_Clean,
            {"Facility_ID"},
            Readmission_Clean,
            {"Facility_ID"},
            "ReadmissionMatch",
            JoinKind.LeftAnti
        )
in
    Source;

shared QA_Model_Summary =
let
    HospitalRows =
        Table.RowCount(Hospital_Clean),

    HospitalDistinctIDs =
        List.Count(
            List.Distinct(
                Hospital_Clean[Facility_ID]
            )
        ),

    BlankFacilityIDs =
        Table.RowCount(
            Table.SelectRows(
                Hospital_Clean,
                each
                    [Facility_ID] = null
                    or Text.Trim([Facility_ID]) = ""
            )
        ),

    InvalidFacilityIDLengths =
        Table.RowCount(
            Table.SelectRows(
                Hospital_Clean,
                each
                    [Facility_ID] <> null
                    and Text.Length([Facility_ID]) <> 6
            )
        ),

    InvalidOverallRatings =
        Table.RowCount(
            Table.SelectRows(
                Hospital_Clean,
                each
                    [Overall_Rating] <> null
                    and (
                        [Overall_Rating] < 1
                        or [Overall_Rating] > 5
                    )
            )
        ),

    HCAHPSRows =
        Table.RowCount(HCAHPS_Clean),

    InvalidHCAHPSRows =
        Table.RowCount(
            Table.SelectRows(
                HCAHPS_Clean,
                each
                    List.AnyTrue(
                        List.Transform(
                            {
                                [Nurse_Communication_Pct],
                                [Doctor_Communication_Pct],
                                [Medicine_Communication_Pct],
                                [Discharge_Info_Pct],
                                [Hospital_Rating_9_10_Pct],
                                [Definitely_Recommend_Pct]
                            },
                            (Value) =>
                                Value <> null
                                and (
                                    Value < 0
                                    or Value > 100
                                )
                        )
                    )
            )
        ),

    InvalidResponseRates =
        Table.RowCount(
            Table.SelectRows(
                HCAHPS_Clean,
                each
                    [Survey_Response_Rate_Pct] <> null
                    and (
                        [Survey_Response_Rate_Pct] < 0
                        or [Survey_Response_Rate_Pct] > 100
                    )
            )
        ),

    ReadmissionRows =
        Table.RowCount(Readmission_Clean),

    InvalidReadmissionRates =
        Table.RowCount(
            Table.SelectRows(
                Readmission_Clean,
                each
                    [Readmission_Rate_Pct] <> null
                    and [Readmission_Rate_Pct] < 0
            )
        ),

    AnalysisModelRows =
        Table.RowCount(Analysis_Model),

    AnalysisModelDistinctIDs =
        List.Count(
            List.Distinct(
                Analysis_Model[Facility_ID]
            )
        ),

    HospitalDuplicateGroups =
        Table.RowCount(
            QA_Hospital_Duplicates
        ),

    HCAHPSDuplicateGroups =
        Table.RowCount(
            QA_HCAHPS_Duplicates
        ),

    HCAHPSMetadataIssues =
        Table.RowCount(
            QA_HCAHPS_Metadata_Inconsistencies
        ),

    ReadmissionDuplicateGroups =
        Table.RowCount(
            QA_Readmission_Duplicates
        ),

    HospitalsWithoutHCAHPS =
        Table.RowCount(
            QA_Hospitals_Without_HCAHPS
        ),

    HospitalsWithoutReadmission =
        Table.RowCount(
            QA_Hospitals_Without_Readmission
        ),

    Output =
        #table(
            {"Check", "Result"},
            {
                {
                    "Hospital clean rows",
                    HospitalRows
                },
                {
                    "Distinct hospital Facility IDs",
                    HospitalDistinctIDs
                },
                {
                    "Blank Facility IDs",
                    BlankFacilityIDs
                },
                {
                    "Invalid Facility ID lengths",
                    InvalidFacilityIDLengths
                },
                {
                    "Invalid overall ratings",
                    InvalidOverallRatings
                },
                {
                    "HCAHPS clean rows",
                    HCAHPSRows
                },
                {
                    "HCAHPS rows with invalid percentages",
                    InvalidHCAHPSRows
                },
                {
                    "Invalid survey response rates",
                    InvalidResponseRates
                },
                {
                    "Readmission clean rows",
                    ReadmissionRows
                },
                {
                    "Invalid negative readmission rates",
                    InvalidReadmissionRates
                },
                {
                    "Analysis model rows",
                    AnalysisModelRows
                },
                {
                    "Distinct analysis model Facility IDs",
                    AnalysisModelDistinctIDs
                },
                {
                    "Hospital duplicate groups",
                    HospitalDuplicateGroups
                },
                {
                    "HCAHPS duplicate groups",
                    HCAHPSDuplicateGroups
                },
                {
                    "HCAHPS metadata inconsistency groups",
                    HCAHPSMetadataIssues
                },
                {
                    "Readmission duplicate groups",
                    ReadmissionDuplicateGroups
                },
                {
                    "Hospitals without HCAHPS",
                    HospitalsWithoutHCAHPS
                },
                {
                    "Hospitals without readmission",
                    HospitalsWithoutReadmission
                }
            }
        ),

    SetTypes =
        Table.TransformColumnTypes(
            Output,
            {
                {"Check", type text},
                {"Result", Int64.Type}
            }
        )
in
    SetTypes;


