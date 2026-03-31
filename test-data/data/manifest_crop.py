def fields(heading, items):
    return {"type": "fields", "heading": heading, "items": items}

def table(heading, headers, rows):
    return {"type": "table", "heading": heading, "headers": headers, "rows": rows}

def text(heading, content):
    return {"type": "text", "heading": heading, "content": content}

def sig(label):
    return {"type": "signature", "label": label}


CROP_DOCUMENTS = [
    # =========================================================================
    # SOIL TEST REPORTS (IDs 1-7)
    # =========================================================================

    # ID 1 - HERO - Horob, Spring 2023, North Quarter Section 12
    {
        "id": 1,
        "title": "Soil Test - North Quarter Section 12",
        "farm": "horob",
        "type": "Soil Test Report",
        "tier": "hero",
        "template": "hero/soil_test",
        "date": "April 10, 2023",
        "created_date": "2023-04-10",
        "correspondent": "NDSU Soil Testing Lab",
        "tags": ["horob-family-farms", "2023", "corn", "nitrogen", "phosphorus"],
        "lab_name": "NDSU Soil Testing Lab",
        "lab_address": "1402 Albrecht Blvd, Fargo, ND 58102",
        "lab_phone": "(701) 231-8942",
        "sample_id": "NDSU-2023-04218",
        "field_name": "North Quarter Section 12",
        "sample_date": "March 28, 2023",
        "sample_depth": "0-24 inches",
        "previous_crop": "Soybeans",
        "soil_texture": "Silty clay loam",
        "results": [
            {"parameter": "pH", "value": "6.8", "unit": "", "rating": "Adequate"},
            {"parameter": "Organic Matter", "value": "3.2", "unit": "%", "rating": "Medium"},
            {"parameter": "Nitrate-Nitrogen (NO3-N)", "value": "18", "unit": "ppm", "rating": "Low-Medium"},
            {"parameter": "Olsen Phosphorus", "value": "14", "unit": "ppm", "rating": "Medium"},
            {"parameter": "Potassium (K)", "value": "280", "unit": "ppm", "rating": "High"},
            {"parameter": "Sulfate-Sulfur (SO4-S)", "value": "8", "unit": "ppm", "rating": "Low"},
            {"parameter": "Zinc (Zn)", "value": "1.2", "unit": "ppm", "rating": "Adequate"},
        ],
        "recommendations": (
            "For a corn yield goal of 180 bu/ac following soybeans: Apply 120 lbs/ac nitrogen "
            "as urea or UAN solution. Credit 40 lbs N from previous soybean crop. Apply 40 lbs/ac "
            "P2O5 to build phosphorus levels. Sulfur is low; apply 15 lbs/ac elemental S. Potassium "
            "and zinc levels are adequate and do not require additional application."
        ),
        "notes": (
            "Samples collected on a 2.5-acre grid pattern, 12 cores per composite sample. "
            "Soil was frozen below 18 inches at time of sampling. Recommend re-testing in fall "
            "after harvest for nitrogen credit adjustments."
        ),
    },

    # ID 2 - Standard - Horob, Spring 2023, South 80
    {
        "id": 2,
        "title": "Soil Test - South 80",
        "farm": "horob",
        "type": "Soil Test Report",
        "tier": "standard",
        "template": "standard",
        "date": "April 18, 2023",
        "created_date": "2023-04-18",
        "correspondent": "NDSU Soil Testing Lab",
        "tags": ["horob-family-farms", "2023", "soybeans"],
        "sections": [
            fields("Sample Information", [
                ("Lab", "NDSU Soil Testing Lab"),
                ("Sample ID", "NDSU-2023-05103"),
                ("Field", "South 80"),
                ("Sample Date", "April 3, 2023"),
                ("Depth", "0-24 inches"),
                ("Previous Crop", "Corn"),
                ("Soil Texture", "Clay loam"),
            ]),
            table("Test Results", ["Parameter", "Value", "Rating"], [
                ["pH", "7.1", "Adequate"],
                ["Organic Matter", "3.6%", "Medium-High"],
                ["NO3-N", "12 ppm", "Low"],
                ["Olsen P", "18 ppm", "Medium-High"],
                ["K", "310 ppm", "High"],
                ["SO4-S", "6 ppm", "Low"],
                ["Zn", "0.9 ppm", "Marginal"],
            ]),
            text("Recommendations", (
                "For soybeans: No nitrogen application needed. Phosphorus levels are adequate "
                "for soybeans. Apply 10 lbs/ac sulfur. Consider 1 lb/ac zinc as starter. "
                "Inoculate seed with Bradyrhizobium japonicum if field has not grown soybeans "
                "in the last 3 years."
            )),
        ],
    },

    # ID 3 - Standard - Horob, Spring 2024, West Field
    {
        "id": 3,
        "title": "Soil Test - West Field",
        "farm": "horob",
        "type": "Soil Test Report",
        "tier": "standard",
        "template": "standard",
        "date": "March 25, 2024",
        "created_date": "2024-03-25",
        "correspondent": "NDSU Soil Testing Lab",
        "tags": ["horob-family-farms", "2024", "corn", "nitrogen"],
        "sections": [
            fields("Sample Information", [
                ("Lab", "NDSU Soil Testing Lab"),
                ("Sample ID", "NDSU-2024-02847"),
                ("Field", "West Field"),
                ("Sample Date", "March 12, 2024"),
                ("Depth", "0-24 inches"),
                ("Previous Crop", "Wheat"),
                ("Soil Texture", "Silty clay loam"),
            ]),
            table("Test Results", ["Parameter", "Value", "Rating"], [
                ["pH", "7.3", "Slightly Alkaline"],
                ["Organic Matter", "2.8%", "Low-Medium"],
                ["NO3-N", "8 ppm", "Very Low"],
                ["Olsen P", "11 ppm", "Low-Medium"],
                ["K", "245 ppm", "Medium-High"],
                ["SO4-S", "10 ppm", "Medium"],
                ["Zn", "1.0 ppm", "Adequate"],
            ]),
            text("Recommendations", (
                "For a corn yield goal of 175 bu/ac following wheat: Apply 160 lbs/ac nitrogen. "
                "No soybean N credit available. Apply 50 lbs/ac P2O5. Sulfur is adequate. "
                "Consider split-applying nitrogen: 80 lbs/ac pre-plant, 80 lbs/ac side-dress at V6."
            )),
        ],
    },

    # ID 4 - Standard - Horob, Spring 2025, North Quarter (retest)
    {
        "id": 4,
        "title": "Soil Test - North Quarter Section 12 (Retest)",
        "farm": "horob",
        "type": "Soil Test Report",
        "tier": "standard",
        "template": "standard",
        "date": "March 18, 2025",
        "created_date": "2025-03-18",
        "correspondent": "NDSU Soil Testing Lab",
        "tags": ["horob-family-farms", "2025", "soybeans", "nitrogen"],
        "sections": [
            fields("Sample Information", [
                ("Lab", "NDSU Soil Testing Lab"),
                ("Sample ID", "NDSU-2025-01932"),
                ("Field", "North Quarter Section 12"),
                ("Sample Date", "March 5, 2025"),
                ("Depth", "0-24 inches"),
                ("Previous Crop", "Corn"),
                ("Soil Texture", "Silty clay loam"),
                ("Notes", "Retest of field previously sampled April 2023"),
            ]),
            table("Test Results", ["Parameter", "Value", "Rating"], [
                ["pH", "6.9", "Adequate"],
                ["Organic Matter", "3.3%", "Medium"],
                ["NO3-N", "22 ppm", "Medium"],
                ["Olsen P", "16 ppm", "Medium"],
                ["K", "265 ppm", "Medium-High"],
                ["SO4-S", "12 ppm", "Medium"],
                ["Zn", "1.1 ppm", "Adequate"],
            ]),
            text("Recommendations", (
                "Phosphorus and sulfur levels have improved since 2023 sampling. For soybeans: "
                "No nitrogen required. P levels adequate. Residual sulfur is sufficient. Continue "
                "current fertility program. Next soil test recommended spring 2027."
            )),
        ],
    },

    # ID 5 - HERO - Pattison, Spring 2023, Home Farm East
    {
        "id": 5,
        "title": "Soil Test - Home Farm East",
        "farm": "pattison",
        "type": "Soil Test Report",
        "tier": "hero",
        "template": "hero/soil_test",
        "date": "April 22, 2023",
        "created_date": "2023-04-22",
        "correspondent": "University of Minnesota Soil Testing Lab",
        "tags": ["pattison-acres", "2023", "corn", "nitrogen", "phosphorus"],
        "lab_name": "University of Minnesota Soil Testing Lab",
        "lab_address": "135 Crops Research Bldg, St. Paul, MN 55108",
        "lab_phone": "(612) 625-3101",
        "sample_id": "UMN-2023-11547",
        "field_name": "Home Farm East",
        "sample_date": "April 5, 2023",
        "sample_depth": "0-24 inches",
        "previous_crop": "Soybeans",
        "soil_texture": "Loam",
        "results": [
            {"parameter": "pH", "value": "6.4", "unit": "", "rating": "Slightly Acidic"},
            {"parameter": "Organic Matter", "value": "4.1", "unit": "%", "rating": "High"},
            {"parameter": "Nitrate-Nitrogen (NO3-N)", "value": "24", "unit": "ppm", "rating": "Medium"},
            {"parameter": "Bray P1 Phosphorus", "value": "22", "unit": "ppm", "rating": "High"},
            {"parameter": "Potassium (K)", "value": "195", "unit": "ppm", "rating": "Medium"},
            {"parameter": "Sulfate-Sulfur (SO4-S)", "value": "14", "unit": "ppm", "rating": "Medium"},
            {"parameter": "Zinc (Zn)", "value": "1.8", "unit": "ppm", "rating": "Adequate"},
        ],
        "recommendations": (
            "For a corn yield goal of 190 bu/ac: Apply 100 lbs/ac nitrogen. Credit 45 lbs N "
            "from previous soybean crop and 20 lbs N from high organic matter. Phosphorus is "
            "sufficient; maintenance rate of 20 lbs/ac P2O5 recommended. Potassium is in the "
            "buildup range; apply 60 lbs/ac K2O. No additional sulfur or zinc needed."
        ),
        "notes": (
            "High organic matter is typical for this field due to historical manure applications "
            "from the adjacent cattle lot. pH is trending slightly lower than ideal; consider "
            "liming in the next 2-3 years if pH drops below 6.2."
        ),
    },

    # ID 6 - Standard - Pattison, Spring 2024, River Bottom 40
    {
        "id": 6,
        "title": "Soil Test - River Bottom 40",
        "farm": "pattison",
        "type": "Soil Test Report",
        "tier": "standard",
        "template": "standard",
        "date": "April 8, 2024",
        "created_date": "2024-04-08",
        "correspondent": "University of Minnesota Soil Testing Lab",
        "tags": ["pattison-acres", "2024", "soybeans"],
        "sections": [
            fields("Sample Information", [
                ("Lab", "University of Minnesota Soil Testing Lab"),
                ("Sample ID", "UMN-2024-08394"),
                ("Field", "River Bottom 40"),
                ("Sample Date", "March 22, 2024"),
                ("Depth", "0-24 inches"),
                ("Previous Crop", "Corn"),
                ("Soil Texture", "Silt loam"),
            ]),
            table("Test Results", ["Parameter", "Value", "Rating"], [
                ["pH", "6.6", "Adequate"],
                ["Organic Matter", "3.8%", "Medium-High"],
                ["NO3-N", "28 ppm", "Medium-High"],
                ["Bray P1", "19 ppm", "Medium-High"],
                ["K", "220 ppm", "Medium"],
                ["SO4-S", "18 ppm", "Adequate"],
                ["Zn", "1.5 ppm", "Adequate"],
            ]),
            text("Recommendations", (
                "For soybeans: No nitrogen application needed. Phosphorus and potassium are "
                "adequate for soybeans. Monitor for iron deficiency chlorosis due to slightly "
                "higher pH zones in this field. Select IDC-tolerant soybean varieties."
            )),
        ],
    },

    # ID 7 - Standard - Pattison, Spring 2025, North 160
    {
        "id": 7,
        "title": "Soil Test - North 160",
        "farm": "pattison",
        "type": "Soil Test Report",
        "tier": "standard",
        "template": "standard",
        "date": "March 30, 2025",
        "created_date": "2025-03-30",
        "correspondent": "University of Minnesota Soil Testing Lab",
        "tags": ["pattison-acres", "2025", "corn", "nitrogen"],
        "sections": [
            fields("Sample Information", [
                ("Lab", "University of Minnesota Soil Testing Lab"),
                ("Sample ID", "UMN-2025-03710"),
                ("Field", "North 160"),
                ("Sample Date", "March 14, 2025"),
                ("Depth", "0-24 inches"),
                ("Previous Crop", "Soybeans"),
                ("Soil Texture", "Clay loam"),
            ]),
            table("Test Results", ["Parameter", "Value", "Rating"], [
                ["pH", "6.9", "Adequate"],
                ["Organic Matter", "3.5%", "Medium"],
                ["NO3-N", "15 ppm", "Low-Medium"],
                ["Bray P1", "16 ppm", "Medium"],
                ["K", "205 ppm", "Medium"],
                ["SO4-S", "9 ppm", "Low-Medium"],
                ["Zn", "1.3 ppm", "Adequate"],
            ]),
            text("Recommendations", (
                "For a corn yield goal of 185 bu/ac following soybeans: Apply 130 lbs/ac nitrogen. "
                "Credit 40 lbs N from previous soybean crop. Apply 30 lbs/ac P2O5. Apply 50 lbs/ac "
                "K2O to build potassium. Apply 10 lbs/ac sulfur as ammonium sulfate."
            )),
        ],
    },

    # =========================================================================
    # CROP INSURANCE POLICIES (IDs 8-12)
    # =========================================================================

    # ID 8 - HERO - Horob, Corn Revenue Protection, 2024
    {
        "id": 8,
        "title": "Crop Insurance - Corn Revenue Protection 2024",
        "farm": "horob",
        "type": "Crop Insurance Policy",
        "tier": "hero",
        "template": "hero/crop_insurance",
        "date": "March 15, 2024",
        "created_date": "2024-03-15",
        "correspondent": "NAU Country Insurance",
        "tags": ["horob-family-farms", "2024", "corn", "insurance"],
        "insurer": "NAU Country Insurance Company",
        "insurer_address": "6795 Edmond St, Las Vegas, NV 89118",
        "policy_number": "NAU-2024-ND-0048721",
        "agent_name": "Tom Keller",
        "agent_phone": "(701) 282-4590",
        "insured_name": "Michael Horob / Horob Family Farms",
        "insured_address": "4821 County Road 10, West Fargo, ND 58078",
        "crop": "Corn",
        "county": "Cass County, ND",
        "plan_type": "Revenue Protection (RP)",
        "coverage_level": "75%",
        "aph_yield": "185 bu/ac",
        "projected_price": "$4.66/bu",
        "premium_per_acre": "$14.82",
        "total_premium": "$11,856.00",
        "acres": "800",
        "effective_date": "March 15, 2024",
        "expiration_date": "March 14, 2025",
        "terms": (
            "Revenue Protection provides coverage against loss of revenue caused by price increase, "
            "price decrease, low yields, or a combination of low yields and price change. The revenue "
            "guarantee equals the coverage level multiplied by the APH yield multiplied by the greater "
            "of the projected price or harvest price. Prevented planting coverage is 55% of the "
            "production guarantee. Replant coverage available up to 8 bu/ac equivalent."
        ),
    },

    # ID 9 - Standard - Horob, Soybean RP, 2024
    {
        "id": 9,
        "title": "Crop Insurance - Soybean Revenue Protection 2024",
        "farm": "horob",
        "type": "Crop Insurance Policy",
        "tier": "standard",
        "template": "standard",
        "date": "March 15, 2024",
        "created_date": "2024-03-15",
        "correspondent": "NAU Country Insurance",
        "tags": ["horob-family-farms", "2024", "soybeans", "insurance"],
        "sections": [
            fields("Policy Information", [
                ("Insurer", "NAU Country Insurance Company"),
                ("Policy Number", "NAU-2024-ND-0048722"),
                ("Agent", "Tom Keller, (701) 282-4590"),
                ("Insured", "Michael Horob / Horob Family Farms"),
            ]),
            fields("Coverage Details", [
                ("Crop", "Soybeans"),
                ("County", "Cass County, ND"),
                ("Plan", "Revenue Protection (RP)"),
                ("Coverage Level", "75%"),
                ("APH Yield", "48 bu/ac"),
                ("Projected Price", "$11.55/bu"),
                ("Acres Insured", "800"),
            ]),
            fields("Premium", [
                ("Premium per Acre", "$9.36"),
                ("Total Premium", "$7,488.00"),
                ("Premium Due Date", "September 30, 2024"),
            ]),
            fields("Dates", [
                ("Effective Date", "March 15, 2024"),
                ("Expiration Date", "March 14, 2025"),
                ("Sales Closing Date", "March 15, 2024"),
                ("Acreage Reporting Date", "July 15, 2024"),
            ]),
            text("Terms", (
                "Revenue Protection guarantees revenue based on APH yield and the greater of "
                "projected or harvest price. Coverage level 75% means indemnity is triggered when "
                "actual revenue falls below 75% of guaranteed revenue."
            )),
        ],
    },

    # ID 10 - Standard - Horob, Wheat RP, 2025
    {
        "id": 10,
        "title": "Crop Insurance - Wheat Revenue Protection 2025",
        "farm": "horob",
        "type": "Crop Insurance Policy",
        "tier": "standard",
        "template": "standard",
        "date": "March 15, 2025",
        "created_date": "2025-03-15",
        "correspondent": "NAU Country Insurance",
        "tags": ["horob-family-farms", "2025", "wheat", "insurance"],
        "sections": [
            fields("Policy Information", [
                ("Insurer", "NAU Country Insurance Company"),
                ("Policy Number", "NAU-2025-ND-0051384"),
                ("Agent", "Tom Keller, (701) 282-4590"),
                ("Insured", "Michael Horob / Horob Family Farms"),
            ]),
            fields("Coverage Details", [
                ("Crop", "Hard Red Spring Wheat"),
                ("County", "Cass County, ND"),
                ("Plan", "Revenue Protection (RP)"),
                ("Coverage Level", "70%"),
                ("APH Yield", "52 bu/ac"),
                ("Projected Price", "$7.08/bu"),
                ("Acres Insured", "800"),
            ]),
            fields("Premium", [
                ("Premium per Acre", "$11.20"),
                ("Total Premium", "$8,960.00"),
                ("Premium Due Date", "September 30, 2025"),
            ]),
            fields("Dates", [
                ("Effective Date", "March 15, 2025"),
                ("Expiration Date", "March 14, 2026"),
                ("Sales Closing Date", "March 15, 2025"),
                ("Acreage Reporting Date", "July 15, 2025"),
            ]),
            text("Terms", (
                "Revenue Protection for spring wheat in Cass County, ND. Prevented planting "
                "coverage is 60% of the production guarantee. Replant payment available at "
                "the lesser of 8 bu/ac times the projected price or 20% of the guarantee per acre."
            )),
        ],
    },

    # ID 11 - HERO - Pattison, Corn RP, 2024
    {
        "id": 11,
        "title": "Crop Insurance - Corn Revenue Protection 2024",
        "farm": "pattison",
        "type": "Crop Insurance Policy",
        "tier": "hero",
        "template": "hero/crop_insurance",
        "date": "March 15, 2024",
        "created_date": "2024-03-15",
        "correspondent": "Rural Community Insurance Services",
        "tags": ["pattison-acres", "2024", "corn", "insurance"],
        "insurer": "Rural Community Insurance Services (RCIS)",
        "insurer_address": "8500 Normandale Lake Blvd, Suite 1100, Bloomington, MN 55437",
        "policy_number": "RCIS-2024-MN-0137295",
        "agent_name": "Linda Bergstrom",
        "agent_phone": "(612) 448-7200",
        "insured_name": "Sarah Pattison / Pattison Acres",
        "insured_address": "11280 Pioneer Trail, Minneapolis, MN 55441",
        "crop": "Corn",
        "county": "Hennepin County, MN",
        "plan_type": "Revenue Protection (RP)",
        "coverage_level": "75%",
        "aph_yield": "192 bu/ac",
        "projected_price": "$4.66/bu",
        "premium_per_acre": "$16.04",
        "total_premium": "$8,020.00",
        "acres": "500",
        "effective_date": "March 15, 2024",
        "expiration_date": "March 14, 2025",
        "terms": (
            "Revenue Protection provides coverage against loss of revenue caused by price change, "
            "low yields, or a combination thereof. The guarantee equals 75% of APH yield times the "
            "greater of projected or harvest price. Enterprise unit structure applies. Prevented "
            "planting coverage at 55% of production guarantee. Late planting period begins June 1."
        ),
    },

    # ID 12 - Standard - Pattison, Soybean YP, 2025
    {
        "id": 12,
        "title": "Crop Insurance - Soybean Yield Protection 2025",
        "farm": "pattison",
        "type": "Crop Insurance Policy",
        "tier": "standard",
        "template": "standard",
        "date": "March 15, 2025",
        "created_date": "2025-03-15",
        "correspondent": "Rural Community Insurance Services",
        "tags": ["pattison-acres", "2025", "soybeans", "insurance"],
        "sections": [
            fields("Policy Information", [
                ("Insurer", "Rural Community Insurance Services (RCIS)"),
                ("Policy Number", "RCIS-2025-MN-0149831"),
                ("Agent", "Linda Bergstrom, (612) 448-7200"),
                ("Insured", "Sarah Pattison / Pattison Acres"),
            ]),
            fields("Coverage Details", [
                ("Crop", "Soybeans"),
                ("County", "Hennepin County, MN"),
                ("Plan", "Yield Protection (YP)"),
                ("Coverage Level", "70%"),
                ("APH Yield", "52 bu/ac"),
                ("Projected Price", "$11.73/bu"),
                ("Acres Insured", "500"),
            ]),
            fields("Premium", [
                ("Premium per Acre", "$7.85"),
                ("Total Premium", "$3,925.00"),
                ("Premium Due Date", "September 30, 2025"),
            ]),
            fields("Dates", [
                ("Effective Date", "March 15, 2025"),
                ("Expiration Date", "March 14, 2026"),
                ("Sales Closing Date", "March 15, 2025"),
                ("Acreage Reporting Date", "July 15, 2025"),
            ]),
            text("Terms", (
                "Yield Protection provides coverage against production losses only. Unlike "
                "Revenue Protection, there is no price component. Indemnity is triggered when "
                "actual yield falls below 70% of the APH yield."
            )),
        ],
    },

    # =========================================================================
    # SEED CONTRACTS (IDs 13-19)
    # =========================================================================

    # ID 13 - HERO - Horob, Pioneer corn seed, Spring 2024
    {
        "id": 13,
        "title": "Seed Contract - Pioneer Corn 2024",
        "farm": "horob",
        "type": "Seed Contract",
        "tier": "hero",
        "template": "hero/seed_contract",
        "date": "November 15, 2023",
        "created_date": "2023-11-15",
        "correspondent": "Pioneer Seeds - West Fargo",
        "tags": ["horob-family-farms", "2024", "corn"],
        "dealer_name": "Pioneer Seeds - West Fargo",
        "dealer_address": "1520 Main Ave E, West Fargo, ND 58078",
        "sales_rep": "Jason Meyers",
        "sales_rep_phone": "(701) 356-2180",
        "buyer_name": "Michael Horob / Horob Family Farms",
        "buyer_address": "4821 County Road 10, West Fargo, ND 58078",
        "order_date": "November 15, 2023",
        "items": [
            {
                "brand": "Pioneer",
                "variety": "P0589AM",
                "trait": "AcreMax Lepidoptera",
                "unit_type": "80,000-kernel bag",
                "quantity": 140,
                "price_per_unit": 294.00,
                "total": 41160.00,
            },
            {
                "brand": "Pioneer",
                "variety": "P0157AM",
                "trait": "AcreMax Lepidoptera",
                "unit_type": "80,000-kernel bag",
                "quantity": 100,
                "price_per_unit": 289.00,
                "total": 28900.00,
            },
        ],
        "delivery_date": "April 1, 2024",
        "total_amount": "$70,060.00",
        "payment_terms": (
            "50% due at booking ($35,030.00 due December 15, 2023). Remaining 50% due at "
            "delivery. Early pay discount of 2% applied to booking payment if paid by December 1, 2023. "
            "Replant policy: free replant seed up to original quantity if stand is below 26,000 plants/ac "
            "due to seed or trait defect."
        ),
        "notes": (
            "P0589AM is a 105-day hybrid suited for full-season planting on the best ground. "
            "P0157AM is a 101-day hybrid for fields with later planting dates or lighter soils. "
            "Both varieties have strong stalk strength ratings and drought tolerance."
        ),
    },

    # ID 14 - Standard - Horob, DEKALB soybean, Spring 2024
    {
        "id": 14,
        "title": "Seed Contract - DEKALB Soybeans 2024",
        "farm": "horob",
        "type": "Seed Contract",
        "tier": "standard",
        "template": "standard",
        "date": "December 5, 2023",
        "created_date": "2023-12-05",
        "correspondent": "DEKALB / Bayer Crop Science",
        "tags": ["horob-family-farms", "2024", "soybeans"],
        "sections": [
            fields("Dealer Information", [
                ("Dealer", "DEKALB / Bayer Crop Science - Fargo"),
                ("Sales Rep", "Amanda Schultz"),
                ("Phone", "(701) 893-4410"),
            ]),
            fields("Buyer Information", [
                ("Buyer", "Michael Horob / Horob Family Farms"),
                ("Address", "4821 County Road 10, West Fargo, ND 58078"),
                ("Order Date", "December 5, 2023"),
            ]),
            table("Seed Order", ["Variety", "Trait", "Unit Type", "Qty", "Price/Unit", "Total"], [
                ["DKB006-84", "Roundup Ready 2 Xtend", "140K-seed unit", "58", "$59.50", "$3,451.00"],
                ["DKB009-89", "Roundup Ready 2 Xtend", "140K-seed unit", "58", "$61.00", "$3,538.00"],
            ]),
            fields("Order Summary", [
                ("Total Amount", "$6,989.00"),
                ("Delivery Date", "April 15, 2024"),
                ("Payment Terms", "Net 30 from delivery"),
            ]),
            text("Notes", (
                "DKB006-84 is a 0.6 maturity group variety with strong IDC tolerance, recommended "
                "for fields with high pH. DKB009-89 is a 0.9 maturity group for full-season placement. "
                "Both have excellent SDS and white mold tolerance."
            )),
        ],
    },

    # ID 15 - Standard - Horob, Proseed wheat, Fall 2024
    {
        "id": 15,
        "title": "Seed Contract - Proseed Wheat 2025",
        "farm": "horob",
        "type": "Seed Contract",
        "tier": "standard",
        "template": "standard",
        "date": "September 20, 2024",
        "created_date": "2024-09-20",
        "correspondent": "NDSU Soil Testing Lab",
        "tags": ["horob-family-farms", "2025", "wheat"],
        "sections": [
            fields("Dealer Information", [
                ("Dealer", "Proseed - Casselton, ND"),
                ("Sales Rep", "Mark Halvorson"),
                ("Phone", "(701) 347-5510"),
            ]),
            fields("Buyer Information", [
                ("Buyer", "Michael Horob / Horob Family Farms"),
                ("Order Date", "September 20, 2024"),
            ]),
            table("Seed Order", ["Variety", "Class", "Seed Size", "Qty (bu)", "Price/bu", "Total"], [
                ["SY Valda", "HRSW", "Certified", "320", "$14.50", "$4,640.00"],
                ["LCS Trigger", "HRSW", "Certified", "320", "$15.00", "$4,800.00"],
            ]),
            fields("Order Summary", [
                ("Total Amount", "$9,440.00"),
                ("Delivery Date", "March 15, 2025"),
                ("Payment Terms", "Due at delivery"),
                ("Seed Treatment", "CruiserMaxx Vibrance (included)"),
            ]),
            text("Notes", (
                "SY Valda provides excellent protein and test weight for milling quality. "
                "LCS Trigger has strong Fusarium head blight resistance and good standability. "
                "Both varieties are well-adapted to the eastern ND growing region."
            )),
        ],
    },

    # ID 16 - Standard - Horob, Pioneer corn, Spring 2025
    {
        "id": 16,
        "title": "Seed Contract - Pioneer Corn 2025",
        "farm": "horob",
        "type": "Seed Contract",
        "tier": "standard",
        "template": "standard",
        "date": "November 8, 2024",
        "created_date": "2024-11-08",
        "correspondent": "Pioneer Seeds - West Fargo",
        "tags": ["horob-family-farms", "2025", "corn"],
        "sections": [
            fields("Dealer Information", [
                ("Dealer", "Pioneer Seeds - West Fargo"),
                ("Sales Rep", "Jason Meyers"),
                ("Phone", "(701) 356-2180"),
            ]),
            fields("Buyer Information", [
                ("Buyer", "Michael Horob / Horob Family Farms"),
                ("Order Date", "November 8, 2024"),
            ]),
            table("Seed Order", ["Variety", "Trait", "Unit Type", "Qty", "Price/Unit", "Total"], [
                ["P0589AMXT", "AcreMax XTend", "80K bag", "150", "$302.00", "$45,300.00"],
                ["P0339AM", "AcreMax Lepidoptera", "80K bag", "90", "$295.00", "$26,550.00"],
            ]),
            fields("Order Summary", [
                ("Total Amount", "$71,850.00"),
                ("Delivery Date", "April 1, 2025"),
                ("Payment Terms", "50% at booking, 50% at delivery"),
                ("Early Pay Discount", "2% if booking paid by November 30, 2024"),
            ]),
            text("Notes", (
                "Increased P0589AMXT from 140 to 150 bags to cover additional acres rotated into corn. "
                "P0339AM replaces P0157AM for 2025 due to improved drought tolerance rating and "
                "better grey leaf spot resistance."
            )),
        ],
    },

    # ID 17 - Standard - Pattison, Pioneer corn, Spring 2024
    {
        "id": 17,
        "title": "Seed Contract - Pioneer Corn 2024",
        "farm": "pattison",
        "type": "Seed Contract",
        "tier": "standard",
        "template": "standard",
        "date": "November 20, 2023",
        "created_date": "2023-11-20",
        "correspondent": "Pioneer Seeds - West Fargo",
        "tags": ["pattison-acres", "2024", "corn"],
        "sections": [
            fields("Dealer Information", [
                ("Dealer", "Pioneer Seeds - Minneapolis District"),
                ("Sales Rep", "Rachel Novak"),
                ("Phone", "(612) 401-8830"),
            ]),
            fields("Buyer Information", [
                ("Buyer", "Sarah Pattison / Pattison Acres"),
                ("Address", "11280 Pioneer Trail, Minneapolis, MN 55441"),
                ("Order Date", "November 20, 2023"),
            ]),
            table("Seed Order", ["Variety", "Trait", "Unit Type", "Qty", "Price/Unit", "Total"], [
                ["P0622AM", "AcreMax Lepidoptera", "80K bag", "80", "$291.00", "$23,280.00"],
                ["P0407AM", "AcreMax Lepidoptera", "80K bag", "60", "$287.00", "$17,220.00"],
            ]),
            fields("Order Summary", [
                ("Total Amount", "$40,500.00"),
                ("Delivery Date", "April 5, 2024"),
                ("Payment Terms", "50% at booking, 50% at delivery"),
            ]),
            text("Notes", (
                "P0622AM is a 106-day hybrid for the best corn-on-corn acres. P0407AM is a "
                "104-day hybrid for lighter soils on the north end of the operation. Both have "
                "strong Northern Corn Leaf Blight resistance."
            )),
        ],
    },

    # ID 18 - Standard - Pattison, NK soybeans, Spring 2024
    {
        "id": 18,
        "title": "Seed Contract - NK Soybeans 2024",
        "farm": "pattison",
        "type": "Seed Contract",
        "tier": "standard",
        "template": "standard",
        "date": "December 12, 2023",
        "created_date": "2023-12-12",
        "correspondent": "NK Seeds / Syngenta",
        "tags": ["pattison-acres", "2024", "soybeans"],
        "sections": [
            fields("Dealer Information", [
                ("Dealer", "NK Seeds / Syngenta - Minneapolis"),
                ("Sales Rep", "Brian Erickson"),
                ("Phone", "(612) 377-5120"),
            ]),
            fields("Buyer Information", [
                ("Buyer", "Sarah Pattison / Pattison Acres"),
                ("Order Date", "December 12, 2023"),
            ]),
            table("Seed Order", ["Variety", "Trait", "Unit Type", "Qty", "Price/Unit", "Total"], [
                ["NK S29-K2", "Roundup Ready 2 Yield", "140K unit", "60", "$56.00", "$3,360.00"],
                ["NK S24-E5", "Enlist E3", "140K unit", "40", "$62.00", "$2,480.00"],
            ]),
            fields("Order Summary", [
                ("Total Amount", "$5,840.00"),
                ("Delivery Date", "April 10, 2024"),
                ("Payment Terms", "Net 30 from delivery"),
                ("Seed Treatment", "CruiserMaxx + Saltro (included)"),
            ]),
            text("Notes", (
                "NK S29-K2 is a 2.9 maturity with excellent yield potential and white mold tolerance. "
                "NK S24-E5 is an Enlist E3 variety for fields with resistant weed issues. "
                "Saltro seed treatment provides SDS protection."
            )),
        ],
    },

    # ID 19 - Standard - Pattison, DEKALB corn, Spring 2025
    {
        "id": 19,
        "title": "Seed Contract - DEKALB Corn 2025",
        "farm": "pattison",
        "type": "Seed Contract",
        "tier": "standard",
        "template": "standard",
        "date": "November 1, 2024",
        "created_date": "2024-11-01",
        "correspondent": "DEKALB / Bayer Crop Science",
        "tags": ["pattison-acres", "2025", "corn"],
        "sections": [
            fields("Dealer Information", [
                ("Dealer", "DEKALB / Bayer Crop Science - Minneapolis"),
                ("Sales Rep", "Kyle Johannsen"),
                ("Phone", "(612) 509-3340"),
            ]),
            fields("Buyer Information", [
                ("Buyer", "Sarah Pattison / Pattison Acres"),
                ("Order Date", "November 1, 2024"),
            ]),
            table("Seed Order", ["Variety", "Trait", "Unit Type", "Qty", "Price/Unit", "Total"], [
                ["DKC62-89", "VT Double PRO RIB", "80K bag", "90", "$299.00", "$26,910.00"],
                ["DKC58-34", "VT Double PRO RIB", "80K bag", "50", "$292.00", "$14,600.00"],
            ]),
            fields("Order Summary", [
                ("Total Amount", "$41,510.00"),
                ("Delivery Date", "April 1, 2025"),
                ("Payment Terms", "50% at booking, 50% at delivery"),
                ("Early Pay Discount", "3% if booking paid by November 15, 2024"),
            ]),
            text("Notes", (
                "Switching to DEKALB for 2025 corn. DKC62-89 is a 112-day hybrid with top-end "
                "yield potential and excellent drought tolerance. DKC58-34 is a 108-day hybrid "
                "for earlier planting and lighter soils. Both feature VT Double PRO above-ground "
                "insect protection with integrated refuge."
            )),
        ],
    },

    # =========================================================================
    # CHEMICAL APPLICATION RECORDS (IDs 20-26)
    # =========================================================================

    # ID 20 - HERO - Horob, Pre-emerge herbicide corn, May 2024
    {
        "id": 20,
        "title": "Chemical Application - Pre-Emerge Corn May 2024",
        "farm": "horob",
        "type": "Chemical Application Record",
        "tier": "hero",
        "template": "hero/chemical_application",
        "date": "May 8, 2024",
        "created_date": "2024-05-08",
        "correspondent": "Nutrien Ag Solutions - Fargo",
        "tags": ["horob-family-farms", "2024", "corn", "herbicide"],
        "applicator_name": "Nutrien Ag Solutions - Fargo",
        "applicator_address": "3100 39th St S, Fargo, ND 58104",
        "applicator_license": "ND Commercial Applicator #C-4872",
        "application_date": "May 8, 2024",
        "farm_name": "Horob Family Farms",
        "field_name": "North Quarter Section 12, T139N-R49W",
        "acres_treated": 160,
        "products": [
            {
                "name": "Dual II Magnum",
                "epa_reg": "100-818",
                "rate": "1.5",
                "rate_unit": "pt/ac",
                "target": "Waterhemp, foxtail, pigweed",
            },
            {
                "name": "Sharpen",
                "epa_reg": "7969-328",
                "rate": "2.0",
                "rate_unit": "oz/ac",
                "target": "Broadleaf weeds, burndown",
            },
        ],
        "crop": "Corn",
        "crop_stage": "Pre-emergence (planted May 3, 2024)",
        "wind_speed": "8 mph",
        "wind_direction": "NW",
        "temperature": "62 F",
        "humidity": "55%",
        "rei": "24 hours",
        "phi": "N/A (pre-emergence)",
        "applicator_signature": "Certified Applicator: Darren Olson, #C-4872",
    },

    # ID 21 - Standard - Horob, Post-emerge soybeans, June 2024
    {
        "id": 21,
        "title": "Chemical Application - Post-Emerge Soybeans June 2024",
        "farm": "horob",
        "type": "Chemical Application Record",
        "tier": "standard",
        "template": "standard",
        "date": "June 22, 2024",
        "created_date": "2024-06-22",
        "correspondent": "Nutrien Ag Solutions - Fargo",
        "tags": ["horob-family-farms", "2024", "soybeans", "herbicide"],
        "sections": [
            fields("Applicator Information", [
                ("Company", "Nutrien Ag Solutions - Fargo"),
                ("Address", "3100 39th St S, Fargo, ND 58104"),
                ("License", "ND Commercial Applicator #C-4872"),
                ("Certified Applicator", "Darren Olson"),
            ]),
            fields("Application Details", [
                ("Date", "June 22, 2024"),
                ("Farm", "Horob Family Farms"),
                ("Field", "South 80, T139N-R49W"),
                ("Acres Treated", "80"),
                ("Crop", "Soybeans (Roundup Ready 2 Xtend)"),
                ("Crop Stage", "V3-V4 (6-8 inches tall)"),
            ]),
            table("Products Applied", ["Product", "EPA Reg #", "Rate", "Target"], [
                ["Roundup PowerMAX 3", "524-549", "32 oz/ac", "Grasses, broadleaves"],
                ["Warrant", "524-591", "48 oz/ac", "Waterhemp, Palmer amaranth (residual)"],
            ]),
            fields("Weather Conditions", [
                ("Wind Speed", "6 mph"),
                ("Wind Direction", "S"),
                ("Temperature", "74 F"),
                ("Humidity", "48%"),
            ]),
            fields("Restrictions", [
                ("REI", "4 hours (Roundup), 12 hours (Warrant)"),
                ("PHI", "14 days (Roundup), N/A (Warrant)"),
            ]),
            sig("Certified Applicator Signature"),
        ],
    },

    # ID 22 - Standard - Horob, Fungicide wheat, July 2024
    {
        "id": 22,
        "title": "Chemical Application - Fungicide Wheat July 2024",
        "farm": "horob",
        "type": "Chemical Application Record",
        "tier": "standard",
        "template": "standard",
        "date": "July 12, 2024",
        "created_date": "2024-07-12",
        "correspondent": "BASF Agricultural Solutions",
        "tags": ["horob-family-farms", "2024", "wheat", "fungicide"],
        "sections": [
            fields("Applicator Information", [
                ("Company", "Nutrien Ag Solutions - Fargo"),
                ("License", "ND Commercial Applicator #C-4872"),
                ("Certified Applicator", "Darren Olson"),
            ]),
            fields("Application Details", [
                ("Date", "July 12, 2024"),
                ("Farm", "Horob Family Farms"),
                ("Field", "West Field, T139N-R49W"),
                ("Acres Treated", "320"),
                ("Crop", "Hard Red Spring Wheat (SY Valda)"),
                ("Crop Stage", "Feekes 10.5.1 (beginning flowering)"),
                ("Application Method", "Aerial (ND Ag Aviation, Cessna AT-502)"),
            ]),
            table("Products Applied", ["Product", "EPA Reg #", "Rate", "Target"], [
                ["Prosaro 421 SC", "264-862", "6.5 oz/ac", "Fusarium head blight (scab), leaf rust"],
            ]),
            fields("Weather Conditions", [
                ("Wind Speed", "5 mph"),
                ("Wind Direction", "W"),
                ("Temperature", "68 F"),
                ("Humidity", "72%"),
            ]),
            fields("Restrictions", [
                ("REI", "12 hours"),
                ("PHI", "30 days"),
            ]),
            text("Notes", (
                "Application timed to early flowering per NDSU extension recommendations for "
                "Fusarium head blight management. Scab risk model indicated moderate-to-high risk "
                "at time of application. Added NIS surfactant at 0.125% v/v."
            )),
            sig("Certified Applicator Signature"),
        ],
    },

    # ID 23 - Standard - Horob, Pre-emerge corn, May 2025
    {
        "id": 23,
        "title": "Chemical Application - Pre-Emerge Corn May 2025",
        "farm": "horob",
        "type": "Chemical Application Record",
        "tier": "standard",
        "template": "standard",
        "date": "May 10, 2025",
        "created_date": "2025-05-10",
        "correspondent": "Nutrien Ag Solutions - Fargo",
        "tags": ["horob-family-farms", "2025", "corn", "herbicide"],
        "sections": [
            fields("Applicator Information", [
                ("Company", "Nutrien Ag Solutions - Fargo"),
                ("License", "ND Commercial Applicator #C-4872"),
                ("Certified Applicator", "Darren Olson"),
            ]),
            fields("Application Details", [
                ("Date", "May 10, 2025"),
                ("Farm", "Horob Family Farms"),
                ("Field", "North Quarter Section 12, T139N-R49W"),
                ("Acres Treated", "160"),
                ("Crop", "Corn"),
                ("Crop Stage", "Pre-emergence (planted May 6, 2025)"),
            ]),
            table("Products Applied", ["Product", "EPA Reg #", "Rate", "Target"], [
                ["Acuron", "100-1623", "2.5 qt/ac", "Broadleaves, grasses, waterhemp (pre-emerge)"],
            ]),
            fields("Weather Conditions", [
                ("Wind Speed", "10 mph"),
                ("Wind Direction", "NW"),
                ("Temperature", "58 F"),
                ("Humidity", "62%"),
            ]),
            fields("Restrictions", [
                ("REI", "24 hours"),
                ("PHI", "N/A (pre-emergence)"),
            ]),
            text("Notes", (
                "Switched from Dual II Magnum + Sharpen to Acuron for 2025 to provide broader "
                "spectrum residual control. Acuron contains three active ingredients (S-metolachlor, "
                "atrazine, mesotrione, bicyclopyrone) for improved waterhemp control."
            )),
            sig("Certified Applicator Signature"),
        ],
    },

    # ID 24 - Standard - Pattison, Pre-emerge corn, May 2024
    {
        "id": 24,
        "title": "Chemical Application - Pre-Emerge Corn May 2024",
        "farm": "pattison",
        "type": "Chemical Application Record",
        "tier": "standard",
        "template": "standard",
        "date": "May 12, 2024",
        "created_date": "2024-05-12",
        "correspondent": "Nutrien Ag Solutions - Minneapolis",
        "tags": ["pattison-acres", "2024", "corn", "herbicide"],
        "sections": [
            fields("Applicator Information", [
                ("Company", "Nutrien Ag Solutions - Minneapolis"),
                ("Address", "7800 Excelsior Blvd, Hopkins, MN 55343"),
                ("License", "MN Commercial Applicator #20-4831"),
                ("Certified Applicator", "Steve Magnuson"),
            ]),
            fields("Application Details", [
                ("Date", "May 12, 2024"),
                ("Farm", "Pattison Acres"),
                ("Field", "Home Farm East, T117N-R21W"),
                ("Acres Treated", "250"),
                ("Crop", "Corn"),
                ("Crop Stage", "Pre-emergence (planted May 7, 2024)"),
            ]),
            table("Products Applied", ["Product", "EPA Reg #", "Rate", "Target"], [
                ["Resicore", "62719-694", "2.75 qt/ac", "Waterhemp, lambsquarters, foxtail"],
                ["Atrazine 4L", "66222-36", "1.0 qt/ac", "Broadleaf weeds (residual)"],
            ]),
            fields("Weather Conditions", [
                ("Wind Speed", "7 mph"),
                ("Wind Direction", "SW"),
                ("Temperature", "65 F"),
                ("Humidity", "52%"),
            ]),
            fields("Restrictions", [
                ("REI", "12 hours"),
                ("PHI", "N/A (pre-emergence)"),
            ]),
            text("Notes", (
                "Resicore provides three sites of action for resistant weed management. "
                "Atrazine added for additional broadleaf residual. Total atrazine use is within "
                "label limits for Hennepin County groundwater restrictions."
            )),
            sig("Certified Applicator Signature"),
        ],
    },

    # ID 25 - Standard - Pattison, Post-emerge soybeans, June 2024
    {
        "id": 25,
        "title": "Chemical Application - Post-Emerge Soybeans June 2024",
        "farm": "pattison",
        "type": "Chemical Application Record",
        "tier": "standard",
        "template": "standard",
        "date": "June 18, 2024",
        "created_date": "2024-06-18",
        "correspondent": "Nutrien Ag Solutions - Minneapolis",
        "tags": ["pattison-acres", "2024", "soybeans", "herbicide"],
        "sections": [
            fields("Applicator Information", [
                ("Company", "Nutrien Ag Solutions - Minneapolis"),
                ("License", "MN Commercial Applicator #20-4831"),
                ("Certified Applicator", "Steve Magnuson"),
            ]),
            fields("Application Details", [
                ("Date", "June 18, 2024"),
                ("Farm", "Pattison Acres"),
                ("Field", "River Bottom 40, T117N-R21W"),
                ("Acres Treated", "40"),
                ("Crop", "Soybeans (Enlist E3)"),
                ("Crop Stage", "V2-V3 (4-6 inches)"),
            ]),
            table("Products Applied", ["Product", "EPA Reg #", "Rate", "Target"], [
                ["Engenia", "7969-345", "12.8 oz/ac", "Waterhemp, lambsquarters, ragweed"],
                ["Roundup PowerMAX 3", "524-549", "32 oz/ac", "Grasses, broadleaves"],
            ]),
            fields("Weather Conditions", [
                ("Wind Speed", "4 mph"),
                ("Wind Direction", "E"),
                ("Temperature", "71 F"),
                ("Humidity", "58%"),
                ("Temperature Inversion", "None detected"),
            ]),
            fields("Restrictions", [
                ("REI", "24 hours (Engenia), 4 hours (Roundup)"),
                ("PHI", "N/A"),
                ("Downwind Buffer", "110 ft (Engenia)"),
            ]),
            text("Notes", (
                "Engenia (dicamba) applied per label requirements: wind speed 3-10 mph, no "
                "temperature inversion, approved nozzles (TTI11004), boom height 24 inches above "
                "canopy. Volatility Reduction Agent (VRA) added at 1% v/v. Application completed "
                "before county sensitive crop registry cutoff."
            )),
            sig("Certified Applicator Signature"),
        ],
    },

    # ID 26 - Standard - Pattison, Pre-emerge corn, May 2025
    {
        "id": 26,
        "title": "Chemical Application - Pre-Emerge Corn May 2025",
        "farm": "pattison",
        "type": "Chemical Application Record",
        "tier": "standard",
        "template": "standard",
        "date": "May 14, 2025",
        "created_date": "2025-05-14",
        "correspondent": "Nutrien Ag Solutions - Minneapolis",
        "tags": ["pattison-acres", "2025", "corn", "herbicide"],
        "sections": [
            fields("Applicator Information", [
                ("Company", "Nutrien Ag Solutions - Minneapolis"),
                ("License", "MN Commercial Applicator #20-4831"),
                ("Certified Applicator", "Steve Magnuson"),
            ]),
            fields("Application Details", [
                ("Date", "May 14, 2025"),
                ("Farm", "Pattison Acres"),
                ("Field", "North 160, T117N-R21W"),
                ("Acres Treated", "160"),
                ("Crop", "Corn (DEKALB DKC62-89)"),
                ("Crop Stage", "Pre-emergence (planted May 9, 2025)"),
            ]),
            table("Products Applied", ["Product", "EPA Reg #", "Rate", "Target"], [
                ["Resicore XL", "62719-752", "3.0 qt/ac", "Waterhemp, giant ragweed, foxtail"],
            ]),
            fields("Weather Conditions", [
                ("Wind Speed", "9 mph"),
                ("Wind Direction", "NW"),
                ("Temperature", "60 F"),
                ("Humidity", "50%"),
            ]),
            fields("Restrictions", [
                ("REI", "24 hours"),
                ("PHI", "N/A (pre-emergence)"),
            ]),
            text("Notes", (
                "Resicore XL provides four effective sites of action against herbicide-resistant "
                "waterhemp, which has been confirmed in this field. Rain received within 10 days "
                "of application is needed to activate residual activity."
            )),
            sig("Certified Applicator Signature"),
        ],
    },

    # =========================================================================
    # FSA FORMS (IDs 27-32)
    # =========================================================================

    # ID 27 - HERO - Horob, ARC-CO Election (CCC-862), 2024
    {
        "id": 27,
        "title": "FSA Form CCC-862 - ARC-CO Election 2024",
        "farm": "horob",
        "type": "FSA Form",
        "tier": "hero",
        "template": "hero/fsa_form",
        "date": "March 15, 2024",
        "created_date": "2024-03-15",
        "correspondent": "Farm Service Agency - Cass County",
        "tags": ["horob-family-farms", "2024", "corn", "soybeans", "wheat"],
        "office_name": "USDA Farm Service Agency - Cass County",
        "office_address": "3509 Miriam Ave, Suite 200, Bismarck, ND 58501 (Cass County Office: 1680 Main Ave E, West Fargo, ND 58078)",
        "office_phone": "(701) 277-2543",
        "form_number": "CCC-862",
        "form_title": "Farm Program Election - Agriculture Risk Coverage (ARC-CO)",
        "program_name": "Agriculture Risk Coverage - County Option (ARC-CO)",
        "farm_number": "4872",
        "tract_number": "1247",
        "producer_name": "Michael Horob / Horob Family Farms",
        "producer_address": "4821 County Road 10, West Fargo, ND 58078",
        "fields": [
            {"label": "Program Year", "value": "2024"},
            {"label": "Election", "value": "ARC-CO for all covered commodities"},
            {"label": "Covered Commodities", "value": "Corn, Soybeans, Wheat"},
            {"label": "FSA Farm Number", "value": "4872"},
            {"label": "Tract Number", "value": "1247"},
            {"label": "Total Base Acres", "value": "1,840"},
            {"label": "Corn Base Acres", "value": "800"},
            {"label": "Soybean Base Acres", "value": "720"},
            {"label": "Wheat Base Acres", "value": "320"},
            {"label": "ARC-CO Benchmark Revenue (Corn)", "value": "$782.76/ac"},
            {"label": "ARC-CO Guarantee (Corn, 86%)", "value": "$673.17/ac"},
            {"label": "ARC-CO Benchmark Revenue (Soybeans)", "value": "$526.68/ac"},
            {"label": "ARC-CO Guarantee (Soybeans, 86%)", "value": "$452.94/ac"},
        ],
        "payment_info": [
            {"description": "Estimated ARC-CO payment (corn, if triggered)", "amount": "$0.00 (pending harvest data)"},
            {"description": "Estimated ARC-CO payment (soybeans, if triggered)", "amount": "$0.00 (pending harvest data)"},
        ],
        "total_payment": "To be determined after harvest year county data is published",
        "effective_date": "October 1, 2023",
        "signature_date": "March 15, 2024",
        "notes": (
            "Election is irrevocable for the 2024 crop year. ARC-CO payments are issued the "
            "October following the crop year once NASS county yields and MYA prices are finalized. "
            "Payment is calculated as: (Guarantee Revenue - Actual County Revenue) x 85% of base acres, "
            "capped at 10% of benchmark revenue."
        ),
    },

    # ID 28 - Standard - Horob, CRP Annual Rental Payment, 2024
    {
        "id": 28,
        "title": "FSA CRP Annual Rental Payment 2024",
        "farm": "horob",
        "type": "FSA Form",
        "tier": "standard",
        "template": "standard",
        "date": "October 1, 2024",
        "created_date": "2024-10-01",
        "correspondent": "Farm Service Agency - Cass County",
        "tags": ["horob-family-farms", "2024"],
        "sections": [
            fields("Office Information", [
                ("Office", "USDA Farm Service Agency - Cass County"),
                ("Address", "1680 Main Ave E, West Fargo, ND 58078"),
                ("Phone", "(701) 277-2543"),
            ]),
            fields("Contract Details", [
                ("Program", "Conservation Reserve Program (CRP)"),
                ("Contract Number", "CRP-ND-0487-2019"),
                ("Farm Number", "4872"),
                ("Tract Number", "1247"),
                ("Producer", "Michael Horob / Horob Family Farms"),
                ("CRP Acres", "120.4"),
                ("Cover Practice", "CP2 - Permanent Native Grasses"),
                ("Contract Period", "October 1, 2019 - September 30, 2029"),
            ]),
            fields("Payment Information", [
                ("Annual Rental Rate", "$142.00/ac"),
                ("Gross Annual Payment", "$17,096.80"),
                ("Cost-Share Maintenance Deduction", "$0.00"),
                ("Net Payment", "$17,096.80"),
                ("Payment Date", "October 1, 2024"),
            ]),
            text("Notes", (
                "Annual CRP payment for 120.4 acres of permanent native grass cover on erodible "
                "cropland. Mid-contract management (prescribed burn or interseeding) was completed "
                "in fall 2023 per contract requirements. Next management obligation in 2026."
            )),
        ],
    },

    # ID 29 - Standard - Horob, Farm Reconstitution, 2025
    {
        "id": 29,
        "title": "FSA Farm Reconstitution 2025",
        "farm": "horob",
        "type": "FSA Form",
        "tier": "standard",
        "template": "standard",
        "date": "January 22, 2025",
        "created_date": "2025-01-22",
        "correspondent": "Farm Service Agency - Cass County",
        "tags": ["horob-family-farms", "2025"],
        "sections": [
            fields("Office Information", [
                ("Office", "USDA Farm Service Agency - Cass County"),
                ("Phone", "(701) 277-2543"),
            ]),
            fields("Reconstitution Details", [
                ("Form", "FSA-155 (Farm Record Change)"),
                ("Type", "Combination - Adding purchased land to existing farm"),
                ("Existing Farm Number", "4872"),
                ("Producer", "Michael Horob / Horob Family Farms"),
            ]),
            table("Land Changes", ["Description", "Acres", "Legal Description"], [
                ["Existing Farm #4872", "2,400.0", "Multiple tracts, T139N-R49W"],
                ["Purchased parcel (from Estate of R. Knutson)", "160.0", "NW 1/4 Sec 14, T139N-R49W"],
                ["New Farm #4872 Total", "2,560.0", ""],
            ]),
            fields("Updated Base Acres", [
                ("Previous Total Base", "1,840"),
                ("Added Base (from Farm #5103)", "124"),
                ("New Total Base", "1,964"),
                ("Corn Base", "850"),
                ("Soybean Base", "780"),
                ("Wheat Base", "334"),
            ]),
            text("Notes", (
                "Reconstitution effective January 15, 2025. Purchased parcel was previously "
                "part of Farm #5103 (Knutson estate). Base acres transferred with the land per "
                "FSA rules. ARC-CO election carries over for transferred base acres for the "
                "2025 program year."
            )),
            sig("County Executive Director"),
            sig("Producer Signature"),
        ],
    },

    # ID 30 - HERO - Nerd Out, Livestock Indemnity Program, 2024
    {
        "id": 30,
        "title": "FSA Livestock Indemnity Program Payment 2024",
        "farm": "nerdout",
        "type": "FSA Form",
        "tier": "hero",
        "template": "hero/fsa_form",
        "date": "April 10, 2024",
        "created_date": "2024-04-10",
        "correspondent": "Farm Service Agency - Cass County",
        "tags": ["nerd-out-ranch", "2024", "cattle"],
        "office_name": "USDA Farm Service Agency - Cass County",
        "office_address": "1680 Main Ave E, West Fargo, ND 58078",
        "office_phone": "(701) 277-2543",
        "form_number": "CCC-770",
        "form_title": "Livestock Indemnity Program (LIP) Application",
        "program_name": "Livestock Indemnity Program (LIP)",
        "farm_number": "5291",
        "tract_number": "2084",
        "producer_name": "Jake Nerdout / Nerd Out Ranch",
        "producer_address": "8940 Sheyenne St, Fargo, ND 58104",
        "fields": [
            {"label": "Program Year", "value": "2024"},
            {"label": "Eligible Loss Condition", "value": "Extreme winter storm (blizzard) - January 9-12, 2024"},
            {"label": "Disaster Designation", "value": "USDA Secretarial Disaster S-4891, Cass County ND"},
            {"label": "Livestock Type", "value": "Beef cattle"},
            {"label": "Category", "value": "Adult cows (>2 years)"},
            {"label": "Number of Head Lost", "value": "12"},
            {"label": "Normal Mortality (deducted)", "value": "2"},
            {"label": "Eligible Losses", "value": "10"},
            {"label": "Payment Rate (75% of market value)", "value": "$1,375.50/head"},
            {"label": "Livestock Type 2", "value": "Beef cattle"},
            {"label": "Category 2", "value": "Calves (<400 lbs)"},
            {"label": "Number of Head Lost 2", "value": "8"},
            {"label": "Normal Mortality (deducted) 2", "value": "2"},
            {"label": "Eligible Losses 2", "value": "6"},
            {"label": "Payment Rate 2 (75% of market value)", "value": "$412.50/head"},
        ],
        "payment_info": [
            {"description": "Adult cows: 10 head x $1,375.50", "amount": "$13,755.00"},
            {"description": "Calves: 6 head x $412.50", "amount": "$2,475.00"},
        ],
        "total_payment": "$16,230.00",
        "effective_date": "January 12, 2024",
        "signature_date": "April 10, 2024",
        "notes": (
            "Losses occurred during severe blizzard January 9-12, 2024. Wind chill reached -55 F. "
            "Livestock were in winter pasture with windbreaks but extreme conditions caused losses. "
            "Veterinary certification of death provided by Dr. Hansen, Fargo Veterinary Clinic. "
            "Payment will be issued within 60 days of approval. Producer certifies losses were "
            "directly attributable to the eligible weather event."
        ),
    },

    # ID 31 - Standard - Pattison, PLC Election, 2024
    {
        "id": 31,
        "title": "FSA Form CCC-862 - PLC Election 2024",
        "farm": "pattison",
        "type": "FSA Form",
        "tier": "standard",
        "template": "standard",
        "date": "March 15, 2024",
        "created_date": "2024-03-15",
        "correspondent": "Farm Service Agency - Hennepin County",
        "tags": ["pattison-acres", "2024", "corn", "soybeans"],
        "sections": [
            fields("Office Information", [
                ("Office", "USDA Farm Service Agency - Hennepin County"),
                ("Address", "625 Robert St N, Suite 400, St. Paul, MN 55155 (Hennepin Service Center)"),
                ("Phone", "(763) 295-5036"),
            ]),
            fields("Producer Information", [
                ("Producer", "Sarah Pattison / Pattison Acres"),
                ("Address", "11280 Pioneer Trail, Minneapolis, MN 55441"),
                ("Farm Number", "3194"),
                ("Tract Number", "876"),
            ]),
            fields("Election Details", [
                ("Form", "CCC-862"),
                ("Program Year", "2024"),
                ("Election", "Price Loss Coverage (PLC) for all covered commodities"),
                ("Covered Commodities", "Corn, Soybeans"),
                ("Corn Base Acres", "480"),
                ("Soybean Base Acres", "360"),
                ("Total Base Acres", "840"),
            ]),
            fields("PLC Reference Prices", [
                ("Corn Effective Reference Price", "$4.01/bu"),
                ("Soybean Effective Reference Price", "$9.26/bu"),
            ]),
            text("Notes", (
                "PLC election chosen over ARC-CO for 2024 due to expectations of prices falling "
                "below reference levels. PLC provides payments when the MYA price drops below "
                "the effective reference price. Payment = (Reference Price - MYA Price) x "
                "Payment Yield x 85% of base acres."
            )),
            sig("Producer Signature"),
        ],
    },

    # ID 32 - Standard - Pattison, ARC-CO Payment Summary, 2025
    {
        "id": 32,
        "title": "FSA ARC-CO Payment Summary 2025",
        "farm": "pattison",
        "type": "FSA Form",
        "tier": "standard",
        "template": "standard",
        "date": "February 28, 2025",
        "created_date": "2025-02-28",
        "correspondent": "Farm Service Agency - Hennepin County",
        "tags": ["pattison-acres", "2025", "corn", "soybeans"],
        "sections": [
            fields("Office Information", [
                ("Office", "USDA Farm Service Agency - Hennepin County"),
                ("Phone", "(763) 295-5036"),
            ]),
            fields("Producer Information", [
                ("Producer", "Sarah Pattison / Pattison Acres"),
                ("Farm Number", "3194"),
            ]),
            fields("Program Information", [
                ("Program", "Agriculture Risk Coverage - County Option (ARC-CO)"),
                ("Crop Year", "2023 (payment issued 2025)"),
            ]),
            table("Payment Calculation - Corn", ["Component", "Value"], [
                ["ARC-CO Benchmark Revenue", "$798.60/ac"],
                ["ARC-CO Guarantee (86%)", "$686.80/ac"],
                ["Actual County Revenue (Hennepin, 2023)", "$651.42/ac"],
                ["Revenue Shortfall", "$35.38/ac"],
                ["Payment Cap (10% of benchmark)", "$79.86/ac"],
                ["Payment Rate", "$35.38/ac"],
                ["Corn Base Acres x 85%", "408.0 ac"],
                ["Corn ARC-CO Payment", "$14,435.04"],
            ]),
            table("Payment Calculation - Soybeans", ["Component", "Value"], [
                ["ARC-CO Benchmark Revenue", "$531.90/ac"],
                ["ARC-CO Guarantee (86%)", "$457.43/ac"],
                ["Actual County Revenue (Hennepin, 2023)", "$472.18/ac"],
                ["Revenue Shortfall", "$0.00/ac"],
                ["Soybean ARC-CO Payment", "$0.00"],
            ]),
            fields("Payment Summary", [
                ("Total ARC-CO Payment", "$14,435.04"),
                ("Sequestration Reduction (5.7%)", "-$822.80"),
                ("Net Payment", "$13,612.24"),
                ("Payment Date", "February 28, 2025"),
            ]),
            text("Notes", (
                "ARC-CO payment for the 2023 crop year was triggered for corn due to county "
                "revenue falling below the guarantee level. Soybean county revenue exceeded "
                "the guarantee, so no soybean payment was issued. Sequestration reduction "
                "applied per current federal budget requirements."
            )),
        ],
    },

    # =========================================================================
    # NUTRIENT MANAGEMENT PLANS (IDs 33-35)
    # =========================================================================

    # ID 33 - Standard - Horob, Nutrient Management Plan, 2024
    {
        "id": 33,
        "title": "Nutrient Management Plan - 2024 Crop Year",
        "farm": "horob",
        "type": "Nutrient Management Plan",
        "tier": "standard",
        "template": "standard",
        "date": "March 1, 2024",
        "created_date": "2024-03-01",
        "correspondent": "NDSU Soil Testing Lab",
        "tags": ["horob-family-farms", "2024", "corn", "soybeans", "wheat", "nitrogen", "phosphorus"],
        "sections": [
            fields("Plan Information", [
                ("Farm", "Horob Family Farms"),
                ("Producer", "Michael Horob"),
                ("Plan Year", "2024 Crop Year"),
                ("Prepared By", "NDSU Extension - Cass County"),
                ("Total Managed Acres", "2,400"),
            ]),
            table("Crop Rotation & Nutrient Plan", [
                "Field", "Acres", "2024 Crop", "Previous Crop",
                "N Rate (lbs/ac)", "P2O5 (lbs/ac)", "K2O (lbs/ac)", "S (lbs/ac)",
            ], [
                ["North Quarter Sec 12", "160", "Corn", "Soybeans", "140", "40", "0", "15"],
                ["South 80", "80", "Soybeans", "Corn", "0", "0", "0", "10"],
                ["West Field", "320", "Corn", "Wheat", "160", "50", "0", "0"],
                ["East 200", "200", "Soybeans", "Corn", "0", "20", "0", "10"],
                ["Southeast Quarter", "160", "Wheat", "Soybeans", "100", "30", "0", "10"],
                ["CRP Acres", "120", "CRP (no crop)", "N/A", "0", "0", "0", "0"],
            ]),
            table("Fertilizer Products & Quantities", [
                "Product", "Analysis", "Total Tons", "Application Method",
            ], [
                ["Anhydrous Ammonia", "82-0-0", "58.5", "Knife injection, pre-plant"],
                ["MAP (11-52-0)", "11-52-0", "18.2", "Broadcast and incorporate"],
                ["Ammonium Sulfate", "21-0-0-24S", "14.4", "Blended with MAP"],
                ["UAN 28%", "28-0-0", "12.0", "Side-dress at V6 (corn)"],
            ]),
            fields("4R Nutrient Stewardship", [
                ("Right Source", "Anhydrous for primary N; MAP for P with starter N; AMS for sulfur"),
                ("Right Rate", "Based on NDSU soil test recommendations and yield goals"),
                ("Right Time", "Pre-plant N injection; side-dress N at V6; P and S at planting"),
                ("Right Place", "Knife injection 6-8 inches deep; broadcast P incorporated within 24 hrs"),
            ]),
            text("Environmental Compliance", (
                "This plan complies with ND Department of Health nutrient management guidelines. "
                "No application within 100 feet of waterways or drainage inlets. Setback of 300 feet "
                "from any wells. Phosphorus application is below the P Index critical level for all "
                "fields. Nitrogen rates do not exceed NDSU maximum return to nitrogen (MRTN) "
                "recommendations for the eastern ND corn growing region."
            )),
            sig("Producer Signature"),
            sig("Certified Crop Adviser (CCA)"),
        ],
    },

    # ID 34 - Standard - Horob, Nutrient Management Plan, 2025
    {
        "id": 34,
        "title": "Nutrient Management Plan - 2025 Crop Year",
        "farm": "horob",
        "type": "Nutrient Management Plan",
        "tier": "standard",
        "template": "standard",
        "date": "February 25, 2025",
        "created_date": "2025-02-25",
        "correspondent": "NDSU Soil Testing Lab",
        "tags": ["horob-family-farms", "2025", "corn", "soybeans", "wheat", "nitrogen", "phosphorus"],
        "sections": [
            fields("Plan Information", [
                ("Farm", "Horob Family Farms"),
                ("Producer", "Michael Horob"),
                ("Plan Year", "2025 Crop Year"),
                ("Prepared By", "NDSU Extension - Cass County"),
                ("Total Managed Acres", "2,560 (includes 160 ac purchased Jan 2025)"),
            ]),
            table("Crop Rotation & Nutrient Plan", [
                "Field", "Acres", "2025 Crop", "Previous Crop",
                "N Rate (lbs/ac)", "P2O5 (lbs/ac)", "K2O (lbs/ac)", "S (lbs/ac)",
            ], [
                ["North Quarter Sec 12", "160", "Soybeans", "Corn", "0", "0", "0", "0"],
                ["South 80", "80", "Corn", "Soybeans", "130", "30", "0", "10"],
                ["West Field", "320", "Soybeans", "Corn", "0", "20", "0", "10"],
                ["East 200", "200", "Corn", "Soybeans", "135", "40", "0", "15"],
                ["Southeast Quarter", "160", "Corn", "Wheat", "155", "45", "0", "10"],
                ["New NW Sec 14", "160", "Wheat", "Soybeans (prev owner)", "110", "35", "0", "10"],
                ["CRP Acres", "120", "CRP (no crop)", "N/A", "0", "0", "0", "0"],
            ]),
            table("Fertilizer Products & Quantities", [
                "Product", "Analysis", "Total Tons", "Application Method",
            ], [
                ["Anhydrous Ammonia", "82-0-0", "52.8", "Knife injection, pre-plant"],
                ["MAP (11-52-0)", "11-52-0", "20.1", "Broadcast and incorporate"],
                ["Ammonium Sulfate", "21-0-0-24S", "11.5", "Blended with MAP"],
                ["UAN 28%", "28-0-0", "14.0", "Side-dress at V6 (corn)"],
            ]),
            fields("4R Nutrient Stewardship", [
                ("Right Source", "Anhydrous for primary N; MAP for P with starter N; AMS for sulfur"),
                ("Right Rate", "Based on spring 2025 soil tests and NDSU MRTN guidelines"),
                ("Right Time", "Pre-plant N injection April; side-dress June; P and S at planting"),
                ("Right Place", "Knife injection 6-8 inches; broadcast P incorporated same day"),
            ]),
            text("Environmental Compliance", (
                "Plan complies with ND Department of Health nutrient management guidelines. "
                "New NW Sec 14 parcel has been soil-tested and baseline nutrient levels documented. "
                "No fields exceed P Index thresholds. Nitrogen rates are at or below MRTN "
                "for each crop and soil zone. Buffer strips maintained along all waterways."
            )),
            sig("Producer Signature"),
            sig("Certified Crop Adviser (CCA)"),
        ],
    },

    # ID 35 - Standard - Pattison, Nutrient Management Plan, 2024
    {
        "id": 35,
        "title": "Nutrient Management Plan - 2024 Crop Year",
        "farm": "pattison",
        "type": "Nutrient Management Plan",
        "tier": "standard",
        "template": "standard",
        "date": "March 5, 2024",
        "created_date": "2024-03-05",
        "correspondent": "University of Minnesota Soil Testing Lab",
        "tags": ["pattison-acres", "2024", "corn", "soybeans", "nitrogen", "phosphorus"],
        "sections": [
            fields("Plan Information", [
                ("Farm", "Pattison Acres"),
                ("Producer", "Sarah Pattison"),
                ("Plan Year", "2024 Crop Year"),
                ("Prepared By", "U of MN Extension - Hennepin County"),
                ("Total Managed Acres", "1,000 (cropland only, excludes pasture)"),
            ]),
            table("Crop Rotation & Nutrient Plan", [
                "Field", "Acres", "2024 Crop", "Previous Crop",
                "N Rate (lbs/ac)", "P2O5 (lbs/ac)", "K2O (lbs/ac)", "S (lbs/ac)",
            ], [
                ["Home Farm East", "250", "Corn", "Soybeans", "140", "20", "60", "0"],
                ["Home Farm West", "200", "Soybeans", "Corn", "0", "0", "40", "0"],
                ["River Bottom 40", "40", "Soybeans", "Corn", "0", "0", "0", "0"],
                ["North 160", "160", "Corn", "Soybeans", "145", "30", "50", "10"],
                ["South 120", "120", "Corn", "Corn", "170", "40", "60", "10"],
                ["West Pasture (hay)", "230", "Grass hay (cattle)", "Grass hay", "60", "0", "0", "0"],
            ]),
            table("Fertilizer Products & Quantities", [
                "Product", "Analysis", "Total Tons", "Application Method",
            ], [
                ["Anhydrous Ammonia", "82-0-0", "40.2", "Knife injection, pre-plant"],
                ["DAP (18-46-0)", "18-46-0", "9.8", "Broadcast and incorporate"],
                ["Potash (0-0-60)", "0-0-60", "14.2", "Broadcast, fall application"],
                ["Ammonium Sulfate", "21-0-0-24S", "4.4", "Blended with DAP"],
                ["Cattle manure", "Approx 10-5-10 lbs/ton", "850 tons", "Surface applied, incorporated within 24 hrs"],
            ]),
            fields("4R Nutrient Stewardship", [
                ("Right Source", "Anhydrous for primary N; DAP for P; manure credited for N-P-K"),
                ("Right Rate", "U of MN guidelines; manure nutrient credits applied per lab analysis"),
                ("Right Time", "Fall K application; spring N and P; manure applied pre-plant and incorporated"),
                ("Right Place", "Knife injection for anhydrous; manure on corn acres only within setbacks"),
            ]),
            text("Manure Management", (
                "Approximately 850 tons of cattle manure from the 200-head feedlot applied to "
                "corn acres at 8 tons/ac. Manure analysis: 10 lbs N/ton, 5 lbs P2O5/ton, "
                "10 lbs K2O/ton. Manure N credit of 80 lbs/ac applied to reduce commercial "
                "fertilizer N rate. Manure incorporated within 24 hours of application to minimize "
                "odor, runoff, and ammonia volatilization."
            )),
            text("Environmental Compliance", (
                "This plan complies with MN Pollution Control Agency (MPCA) feedlot rules and "
                "MN nutrient management guidelines. Manure application setbacks: 300 ft from wells, "
                "100 ft from surface water, 50 ft from property lines. No manure application on "
                "frozen or snow-covered ground. Phosphorus balance is maintained through manure and "
                "commercial fertilizer combined application rates."
            )),
            sig("Producer Signature"),
            sig("Certified Crop Adviser (CCA)"),
        ],
    },
]
