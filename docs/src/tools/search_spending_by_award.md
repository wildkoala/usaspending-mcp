# search_spending_by_award

Search for federal spending awards with various filters.

**API endpoint:** `POST /api/v2/search/spending_by_award/`

## Parameters

All parameters are optional.

| Parameter | Type | Description |
|-----------|------|-------------|
| `keywords` | string | Search keywords |
| `start_date` | string | Start date in `YYYY-MM-DD` format |
| `end_date` | string | End date in `YYYY-MM-DD` format |
| `award_type` | string[] | Award type codes (see below) |
| `agency` | string | Funding agency name |
| `page` | integer | Page number (default: 1) |
| `limit` | integer | Results per page (default: 10, max: 100) |

## Award type codes

| Category | Codes |
|----------|-------|
| Contracts | `A`, `B`, `C`, `D` |
| Grants | `02`, `03`, `04`, `05` |
| Loans | `07`, `08` |
| Direct payments | `06`, `10` |
| Other | `09`, `11` |

If `award_type` is omitted, defaults to contracts (`A`, `B`, `C`, `D`).

## Example

Search for NASA contracts related to "satellite":

```json
{
  "name": "search_spending_by_award",
  "arguments": {
    "keywords": "satellite",
    "agency": "National Aeronautics and Space Administration",
    "award_type": ["A", "B", "C", "D"],
    "limit": 5
  }
}
```

## Response

Returns a formatted text list of matching awards with:
- Award ID
- Recipient name
- Dollar amount
- Description
- Awarding agency
- Period of performance
- Internal ID (for use with `get_award_details`)
