# get_spending_explorer

Explore aggregate federal spending breakdowns for a given fiscal year.

**API endpoint:** `POST /api/v2/spending/`

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `type` | string | yes | Dimension to group by: `budget_function`, `agency`, `object_class`, or `federal_account` |
| `fiscal_year` | integer | yes | Fiscal year (e.g. `2024`) |
| `spending_type` | string | no | `total` (default), `discretionary`, or `mandatory` |

## Example

View spending by agency for FY2024:

```json
{
  "name": "get_spending_explorer",
  "arguments": {
    "type": "agency",
    "fiscal_year": 2024
  }
}
```

View discretionary spending by budget function:

```json
{
  "name": "get_spending_explorer",
  "arguments": {
    "type": "budget_function",
    "fiscal_year": 2024,
    "spending_type": "discretionary"
  }
}
```

## Response

Returns the total spending amount and a ranked list (top 25) of the chosen dimension with dollar amounts.
