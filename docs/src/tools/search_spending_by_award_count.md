# search_spending_by_award_count

Get counts of federal spending awards grouped by type.

**API endpoint:** `POST /api/v2/search/spending_by_award_count/`

## Parameters

All parameters are optional.

| Parameter | Type | Description |
|-----------|------|-------------|
| `keywords` | string | Search keywords |
| `start_date` | string | Start date in `YYYY-MM-DD` format |
| `end_date` | string | End date in `YYYY-MM-DD` format |
| `agency` | string | Funding agency name |

## Example

Count all awards for the Department of Defense in FY2024:

```json
{
  "name": "search_spending_by_award_count",
  "arguments": {
    "agency": "Department of Defense",
    "start_date": "2023-10-01",
    "end_date": "2024-09-30"
  }
}
```

## Response

Returns award counts broken down by type:
- Contracts
- Direct payments
- Grants
- IDVs (Indefinite Delivery Vehicles)
- Loans
- Other
