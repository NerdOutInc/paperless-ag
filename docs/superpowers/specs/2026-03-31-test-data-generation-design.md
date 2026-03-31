# Test Data Generation Design

**Date:** 2026-03-31
**Purpose:** Generate 100 fake farm/ranch PDFs for testing Paperless NGX and the semantic search companion container.

---

## Overview

Generate 100 realistic PDF documents representing the paperwork that farms and ranches accumulate. Upload them to a local Paperless NGX instance (localhost:8000) via the REST API with pre-assigned metadata (correspondents, document types, tags). This provides immediate test data for developing the pgvector semantic search companion container.

## Farms

Three fictional operations provide document diversity:

| Farm | Type | Location | Notes |
|---|---|---|---|
| **Horob Family Farms** | 2,400 ac row crops (corn/soybeans/wheat) | West Fargo, ND | Primary source for crop-related documents |
| **Nerd Out Ranch** | 800 head cow-calf operation | Fargo, ND | Primary source for livestock documents |
| **Pattison Acres** | 1,200 ac diversified (corn/soybeans + 200 head cattle) | Minneapolis, MN | Mix of crop and livestock documents |

All three are in the upper Midwest (ND/MN), so FSA offices, state agencies, and regional vendors are geographically consistent.

## Document Types & Distribution

100 documents total: 20 hero (polished visual design) + 80 standard (content-focused). Date range: January 2023 -- March 2026.

| Document Type | Horob | Nerd Out | Pattison | Total | Hero |
|---|---|---|---|---|---|
| Soil Test Reports | 4 | -- | 3 | 7 | 2 |
| Crop Insurance Policies | 3 | -- | 2 | 5 | 2 |
| Seed Contracts / Invoices | 4 | -- | 3 | 7 | 1 |
| Chemical Application Records | 4 | -- | 3 | 7 | 1 |
| FSA Forms (CRP, ARC/PLC, etc.) | 3 | 1 | 2 | 6 | 2 |
| Cash Rent / Land Leases | 3 | -- | 2 | 5 | 2 |
| Grain Elevator Receipts / Scale Tickets | 4 | -- | 3 | 7 | 1 |
| Equipment Purchase / Service Records | 2 | 2 | 3 | 7 | 1 |
| Cattle Health / Vet Records | -- | 5 | 2 | 7 | 2 |
| Livestock Insurance | -- | 3 | 1 | 4 | 1 |
| Grazing Permits / Pasture Leases | -- | 3 | 1 | 4 | 1 |
| Property Tax Statements | 2 | 2 | 2 | 6 | 1 |
| Feed / Hay Purchase Agreements | -- | 4 | 2 | 6 | 1 |
| Succession Planning / Estate Docs | 1 | 1 | 1 | 3 | 1 |
| Equipment Manuals (excerpts) | 2 | 1 | 1 | 4 | -- |
| Miscellaneous (brand certs, water rights, etc.) | 1 | 4 | 3 | 8 | 1 |
| Nutrient Management Plans | 2 | -- | 1 | 3 | -- |
| **Totals** | **35** | **26** | **35** | **96** | **20** |

The remaining 4 documents are flexible -- allocated during generation to fill gaps or add variety.

## Generation Pipeline

### Directory Structure

```
test-data/
├── generate.py          # Main script: renders HTML, converts to PDF, uploads
├── templates/
│   ├── hero/            # 20 polished Jinja2 HTML templates (one per hero doc)
│   └── standard/        # ~15 reusable templates (one per document type)
├── data/
│   ├── farms.json       # Farm definitions, contacts, correspondents
│   └── documents.json   # Manifest of all 100 docs with metadata + template data
├── output/              # Generated PDFs
└── requirements.txt     # jinja2, requests
```

### Generation Flow

1. `generate.py` reads `documents.json` manifest
2. For each document: renders HTML from its Jinja2 template with the document's data
3. Writes HTML to a temp file, converts via `chrome --headless --print-to-pdf`
4. Repeats for all 100 documents
5. Uploads each PDF to Paperless NGX via `POST /api/documents/post_document/` with metadata

### Chrome PDF Conversion

```bash
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --headless --disable-gpu --no-sandbox \
  --print-to-pdf=output/document.pdf \
  temp/document.html
```

## Hero vs Standard Documents

### Hero Documents (20)

Full visual treatment per template:
- Letterheads with company/agency names and addresses
- Styled headers with colored backgrounds or borders
- Data tables with proper formatting
- Form-like layouts with labeled fields
- Signature lines and date fields
- Fine print and disclaimers where appropriate

Each hero document is a unique HTML template. These are good for demos and screenshots.

### Standard Documents (80)

Content-focused with minimal styling:
- Clean sans-serif typography (system font stack)
- Proper heading hierarchy (h1/h2/h3)
- Tables where the document type calls for them
- No letterheads, logos, or visual flourish

~15 reusable Jinja2 templates (one per document type), rendered with varied data to produce 80 distinct documents.

## Paperless NGX Metadata

### Correspondents

Each document is assigned a correspondent representing its source. Examples:

- NDSU Soil Testing Lab
- Pioneer Seeds (West Fargo)
- Corteva Agriscience
- State Farm Crop Insurance
- Farm Service Agency -- Cass County
- Farm Service Agency -- Hennepin County
- Titan Machinery
- Fargo Veterinary Clinic
- Cass County Tax Assessor
- Hennepin County Property Tax

### Document Types

Created in Paperless to match the categories in the distribution table:
- Soil Test Report
- Crop Insurance Policy
- Seed Contract
- Chemical Application Record
- FSA Form
- Land Lease
- Grain Receipt
- Equipment Record
- Veterinary Record
- Livestock Insurance Policy
- Grazing Permit
- Property Tax Statement
- Feed Purchase Agreement
- Succession Plan
- Equipment Manual
- Nutrient Management Plan
- Brand Certificate
- Water Rights Permit

### Tags

Each document gets 2-4 tags:
- **Farm name:** `horob-family-farms`, `nerd-out-ranch`, `pattison-acres`
- **Year:** `2023`, `2024`, `2025`, `2026`
- **Topical tags (selected per doc):** `corn`, `soybeans`, `wheat`, `cattle`, `nitrogen`, `phosphorus`, `herbicide`, `insurance`, `lease`, `tax`, `equipment`, `hay`

## Content Strategy

Document text uses realistic technical language to enable meaningful semantic search testing:

- **Soil tests:** Actual nutrient levels (N, P, K, pH, organic matter), recommendations like "apply 120 lbs/ac anhydrous ammonia"
- **Chemical records:** Real herbicide/pesticide names (Roundup PowerMAX, Warrant, Engenia), application rates, REI/PHI intervals
- **Crop insurance:** Plausible policy numbers, APH yields, coverage levels (75% RP), premium calculations
- **FSA forms:** Program names (ARC-CO, PLC, CRP), farm/tract numbers, payment calculations
- **Cattle records:** Ear tag numbers, vaccination records (Blackleg, IBR/BVD), breeding dates, calving records
- **Leases:** Legal descriptions (Section-Township-Range), payment terms, landlord/tenant names

### Semantic Search Test Queries

The content should enable these example queries to return meaningful results:
- "find me everything related to nitrogen management" -- hits soil tests, chemical records, nutrient management plans
- "what did my soil test say about phosphorus levels" -- finds specific soil test results with P levels
- "crop insurance documents from 2024" -- date range + type filtering
- "how much did I pay for seed last year" -- seed contracts/invoices
- "cattle vaccination records" -- vet records with vaccine names
- "what are the terms of my lease on the section 12 land" -- land lease with legal description

## Upload Script

The upload step uses the Paperless NGX REST API:

1. Authenticate: get API token via `POST /api/token/` with admin/admin credentials
2. Create document types via `POST /api/document_types/`
3. Create correspondents via `POST /api/correspondents/`
4. Create tags via `POST /api/tags/`
5. Upload each PDF via `POST /api/documents/post_document/` with multipart form data including the PDF file and metadata fields (title, correspondent, document_type, tags, created date)

The script is idempotent -- it checks for existing document types/correspondents/tags before creating them.
