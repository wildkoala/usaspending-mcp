# list_agencies

List top-tier federal agencies with budget authority, obligated amounts, and outlays.

**API endpoint:** `GET /api/v2/references/toptier_agencies/`

## Parameters

All parameters are optional.

| Parameter | Type | Description |
|-----------|------|-------------|
| `sort` | string | Sort field (see below). Default: `budget_authority_amount` |
| `order` | string | `asc` or `desc` (default: `desc`) |

### Sort fields

- `agency_name`
- `active_fy`
- `outlay_amount`
- `obligated_amount`
- `budget_authority_amount`
- `current_total_budget_authority_amount`
- `percentage_of_total_budget_authority`

## Example

List agencies sorted by obligated amount:

```json
{
  "name": "list_agencies",
  "arguments": {
    "sort": "obligated_amount",
    "order": "desc"
  }
}
```

## Response

Returns all top-tier federal agencies with:
- Agency name
- Budget authority amount
- Obligated amount
- Outlay amount
- Percentage of total federal budget
- Active fiscal year
