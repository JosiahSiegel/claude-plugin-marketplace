# Identity Resolution

Reference for Data Cloud identity resolution rules and custom matching logic.

## Matching Rules

Configure identity resolution to create unified profiles:

```text
Match Rules Configuration:
├─ Primary Match (exact match on email)
│  └─ IF email matches THEN merge profiles
├─ Secondary Match (fuzzy match on name + phone)
│  └─ IF firstName + lastName similar AND phone matches THEN merge
└─ Tertiary Match (external ID)
   └─ IF ExternalCustomerId matches THEN merge

Reconciliation Rules (conflict resolution):
├─ Most Recent: Use most recently updated value
├─ Source Priority: Salesforce > ERP > Website
└─ Field-Level Rules: Email from Salesforce, Revenue from ERP
```

## Custom Matching Logic

```apex
public class DataCloudMatchingService {
    public static Boolean shouldMatch(Map<String, Object> profile1,
                                     Map<String, Object> profile2) {
        String email1 = (String)profile1.get('email');
        String email2 = (String)profile2.get('email');

        // Exact email match
        if (email1 != null && email1.equalsIgnoreCase(email2)) {
            return true;
        }

        // Fuzzy name + address match
        String name1 = (String)profile1.get('fullName');
        String name2 = (String)profile2.get('fullName');
        String address1 = (String)profile1.get('address');
        String address2 = (String)profile2.get('address');

        if (isNameSimilar(name1, name2) && isSameAddress(address1, address2)) {
            return true;
        }

        return false;
    }

    private static Boolean isNameSimilar(String name1, String name2) {
        // Implement Levenshtein distance or phonetic matching
        return calculateSimilarity(name1, name2) > 0.85;
    }
}
```

## Authentication: OAuth 2.0 JWT Bearer Flow (Server-to-Server)

```python
# External system → Data Cloud authentication
import jwt
import time
import requests

def get_data_cloud_access_token(client_id, private_key, username, instance_url):
    """Get access token for Data Cloud API"""

    payload = {
        'iss': client_id,
        'sub': username,
        'aud': instance_url,
        'exp': int(time.time()) + 180  # 3 minutes
    }

    encoded_jwt = jwt.encode(payload, private_key, algorithm='RS256')

    token_url = f"{instance_url}/services/oauth2/token"
    response = requests.post(token_url, data={
        'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion': encoded_jwt
    })

    return response.json()['access_token']
```
