# Test Data Generator

Generates 100 fake farm/ranch PDF documents and uploads them to a local Paperless NGX instance. Used for testing the semantic search companion container.

## Quick Start

```bash
cd test-data
pip3 install -r requirements.txt
python3 generate.py        # Generate 100 PDFs in output/
python3 upload.py           # Upload to Paperless at localhost:8000
```

Paperless must be running (`docker compose up -d` from the `Paperless NGX/` directory). Default credentials: admin / admin.

## Scripts

| File | Purpose |
| --- | --- |
| `generate.py` | Renders HTML from Jinja2 templates, converts to PDF via Chrome headless. Outputs to `output/`. |
| `upload.py` | Uploads PDFs to Paperless NGX via REST API with metadata (document types, correspondents, tags with colors). |

### generate.py options

```plaintext
--force       Regenerate PDFs even if they already exist
--limit N     Only generate the first N documents
```

### upload.py options

```plaintext
--url URL       Paperless base URL (default: http://localhost:8000)
--username U    Paperless username (default: admin)
--password P    Paperless password (default: admin)
--limit N       Only upload the first N documents
--skip-setup    Skip creating document types/correspondents/tags
--dry-run       Show what would be uploaded without uploading
```

## Directory Structure

```plaintext
test-data/
├── generate.py              # HTML rendering + Chrome PDF conversion
├── upload.py                # Paperless API upload + metadata setup
├── requirements.txt         # Python dependencies (jinja2, requests)
├── data/
│   ├── farms.py             # Farm definitions, correspondents, document types, tags
│   ├── manifest.py          # Combines all document entries (imports from below)
│   ├── manifest_crop.py     # Docs 1-35: soil tests, insurance, seed, chemical, FSA, nutrient plans
│   ├── manifest_livestock.py # Docs 36-70: leases, grain receipts, equipment, vet, livestock insurance, grazing
│   └── manifest_general.py  # Docs 71-100: property tax, feed, succession, manuals, brand certs, misc
├── templates/
│   ├── base_standard.html   # Base template for standard (content-focused) documents
│   ├── base_hero.html       # Base template for hero (polished) documents
│   ├── standard.html        # Generic section-based template used by all 80 standard docs
│   └── hero/                # 15 unique templates for the 20 hero documents
│       ├── soil_test.html
│       ├── crop_insurance.html
│       ├── seed_contract.html
│       ├── chemical_application.html
│       ├── fsa_form.html
│       ├── land_lease.html
│       ├── grain_receipt.html
│       ├── equipment_record.html
│       ├── cattle_health.html
│       ├── livestock_insurance.html
│       ├── grazing_permit.html
│       ├── property_tax.html
│       ├── feed_purchase.html
│       ├── succession_plan.html
│       └── brand_certificate.html
└── output/                  # Generated PDFs (not committed to git)
```

## The Three Farms

| Farm | Type | Location |
| --- | --- | --- |
| Horob Family Farms | 2,400 ac row crops (corn/soybeans/wheat) | West Fargo, ND |
| Nerd Out Ranch | 800 head cow-calf operation | Fargo, ND |
| Pattison Acres | 1,200 ac diversified (corn/soybeans + 200 head cattle) | Minneapolis, MN |

## Document Breakdown

100 documents total across 18 types, spanning January 2023 - March 2026.

- 20 **hero** documents with polished visual designs (letterheads, styled tables, colored themes)
- 80 **standard** documents with clean, content-focused layouts

| Document Type | Count |
| --- | --- |
| Soil Test Reports | 7 |
| Crop Insurance Policies | 5 |
| Seed Contracts | 7 |
| Chemical Application Records | 7 |
| FSA Forms | 6 |
| Land Leases | 5 |
| Grain Elevator Receipts | 7 |
| Equipment Records | 7 |
| Cattle Health / Vet Records | 7 |
| Livestock Insurance | 4 |
| Grazing Permits | 4 |
| Property Tax Statements | 6 |
| Feed / Hay Purchases | 6 |
| Succession Plans | 3 |
| Equipment Manuals | 4 |
| Nutrient Management Plans | 3 |
| Brand Certificates / Water Rights / Misc | 12 |

## Requirements

- Python 3.6+
- Google Chrome (used headless for PDF conversion)
- Paperless NGX running locally (for upload step)
