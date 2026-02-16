# get_recipient_profile

Get profile information for a federal spending recipient.

**API endpoint:** `GET /api/v2/recipient/{recipient_id}/`

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `recipient_id` | string | yes | Recipient hash ID (UUID format). Obtain this from `search_spending_by_award` or `get_award_details` results. |
| `year` | string | no | Fiscal year, `all`, or `latest` (default: `latest`) |

## Example

```json
{
  "name": "get_recipient_profile",
  "arguments": {
    "recipient_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "year": "2024"
  }
}
```

## Response

Returns a recipient profile with:

- **Identity:** Name, DUNS, UEI, parent organization
- **Location:** Address, city, state, ZIP, country
- **Business types:** Classification categories
- **Spending totals:** Total transaction amount, total awards
- **Breakdown by award type:** Contracts, grants, loans, direct payments, other
