# get_award_details

Get detailed information about a specific federal spending award.

**API endpoint:** `GET /api/v2/awards/{award_id}/`

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `award_id` | string | yes | The award's `generated_unique_award_id` or internal database ID. Obtain this from `search_spending_by_award` results. |

## Example

```json
{
  "name": "get_award_details",
  "arguments": {
    "award_id": "CONT_AWD_0001_9700_SPE2D120F0599_9700"
  }
}
```

## Response

Returns comprehensive award details:

- **Identity:** Award ID, type, category
- **Description:** Contract or assistance description
- **Amounts:** Total obligation, base and all options value, total outlays
- **Recipient:** Name, ID (for use with `get_recipient_profile`), location
- **Funding agency:** Top-tier agency name
- **Place of performance:** City, state, country
- **Period of performance:** Start and end dates
- **Classification codes:** NAICS, PSC, CFDA

## Workflow

This tool works well in combination with search:

1. Use `search_spending_by_award` to find awards matching your criteria
2. Note the `Internal ID` from the results
3. Use `get_award_details` with that ID to get the full picture
4. Use the recipient ID from the details with `get_recipient_profile`
