# list_federal_accounts

List and search federal accounts with budgetary resource information.

**API endpoint:** `POST /api/v2/federal_accounts/`

## Parameters

All parameters are optional.

| Parameter | Type | Description |
|-----------|------|-------------|
| `keyword` | string | Search accounts by name or number |
| `fiscal_year` | integer | Filter by fiscal year (e.g. `2024`) |
| `agency_identifier` | string | Agency identifier code |
| `sort_field` | string | Sort by: `account_name`, `account_number`, `budgetary_resources`, or `managing_agency` (default: `budgetary_resources`) |
| `sort_direction` | string | `asc` or `desc` (default: `desc`) |
| `page` | integer | Page number (default: 1) |
| `limit` | integer | Results per page (default: 10, max: 100) |

## Example

Search for defense-related accounts:

```json
{
  "name": "list_federal_accounts",
  "arguments": {
    "keyword": "defense",
    "fiscal_year": 2024,
    "limit": 10
  }
}
```

## Response

Returns a paginated list of federal accounts with:
- Account name
- Account number
- Managing agency
- Budgetary resources (dollar amount)
