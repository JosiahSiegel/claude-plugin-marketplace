# Data Cloud Vector Database (GA March 2025)

Reference for vector database, semantic search, hybrid search, and use cases.

## What is Vector Database?

Data Cloud Vector Database ingests, stores, unifies, indexes, and allows semantic queries of unstructured data using generative AI techniques. It creates embeddings that enable semantic querying and seamless integration with structured data in the Einstein platform.

**Supported Unstructured Data:**
- Emails and email threads
- Text documents (PDFs, Word, etc.)
- Social media content
- Web content and chat transcripts
- Call transcripts and recordings
- Knowledge base articles
- Customer reviews and feedback

## How Vector Database Works

```text
┌──────────────────────────────────────────────────────────┐
│            Unstructured Data Sources                     │
│  Emails │ Documents │ Transcripts │ Social │ Knowledge  │
└─────────────────────┬────────────────────────────────────┘
                      │
    ┌─────────────────▼────────────────────────────────────┐
    │          Text Embedding Generation                   │
    │  Uses LLM to convert text → vector embeddings        │
    │  (768-dimensional numeric representations)           │
    └─────────────────┬────────────────────────────────────┘
                      │
    ┌─────────────────▼────────────────────────────────────┐
    │        Vector Database Storage & Indexing            │
    │  Stores embeddings with metadata                     │
    │  Creates high-performance vector index               │
    └─────────────────┬────────────────────────────────────┘
                      │
    ┌─────────────────▼────────────────────────────────────┐
    │           Semantic Search Queries                    │
    │  Natural language query → embedding → similarity     │
    │  Returns most semantically similar content           │
    └──────────────────────────────────────────────────────┘
```

## Semantic Search with Einstein Copilot Search

Semantic search understands the meaning and intent of queries, going beyond keyword matching.

**Example:**
- **Query:** "How do I return a defective product?"
- **Traditional Keyword Search:** Matches documents containing exact words "return", "defective", "product"
- **Semantic Search:** Finds documents about return policies, warranty claims, product exchanges, refund procedures, RMA processes — even if they use different wording.

## Implementing Vector Database

### Step 1: Configure Unstructured Data Sources

```text
Setup → Data Cloud → Data Sources → Create
- Source Type: Unstructured Data
- Options:
  ├─ Salesforce Knowledge
  ├─ EmailMessage object
  ├─ External documents (S3, Azure Blob, Google Drive)
  ├─ API-based ingestion
  └─ ContentDocument/File objects
```

### Step 2: Enable Vector Indexing

```apex
public class VectorDatabaseService {
    public static void indexDocument(String documentId, String content, Map<String, Object> metadata) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:DataCloud/v1/vector/index');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');

        Map<String, Object> payload = new Map<String, Object>{
            'documentId' => documentId,
            'content' => content,
            'metadata' => metadata,
            'source' => 'Salesforce',
            'timestamp' => System.now().getTime()
        };

        req.setBody(JSON.serialize(payload));

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            System.debug('Document indexed: ' + documentId);
        } else {
            System.debug('Indexing failed: ' + res.getBody());
        }
    }
}

// Trigger to auto-index Knowledge articles
trigger KnowledgeArticleTrigger on Knowledge__kav (after insert, after update) {
    for (Knowledge__kav article : Trigger.new) {
        if (article.PublishStatus == 'Online') {
            Map<String, Object> metadata = new Map<String, Object>{
                'articleNumber' => article.ArticleNumber,
                'title' => article.Title,
                'category' => article.Category__c,
                'language' => article.Language
            };

            VectorDatabaseService.indexDocument(
                article.Id,
                article.Body__c,
                metadata
            );
        }
    }
}
```

### Step 3: Perform Semantic Search

```apex
public class SemanticSearchService {
    @InvocableMethod(label='Semantic Search' description='Search unstructured data semantically')
    public static List<SearchResult> semanticSearch(List<SearchRequest> requests) {
        List<SearchResult> results = new List<SearchResult>();

        for (SearchRequest req : requests) {
            HttpRequest httpReq = new HttpRequest();
            httpReq.setEndpoint('callout:DataCloud/v1/vector/search');
            httpReq.setMethod('POST');
            httpReq.setHeader('Content-Type', 'application/json');

            Map<String, Object> payload = new Map<String, Object>{
                'query' => req.query,
                'topK' => req.maxResults,
                'filters' => req.filters,
                'includeMetadata' => true
            };

            httpReq.setBody(JSON.serialize(payload));

            Http http = new Http();
            HttpResponse httpRes = http.send(httpReq);

            if (httpRes.getStatusCode() == 200) {
                Map<String, Object> response = (Map<String, Object>)
                    JSON.deserializeUntyped(httpRes.getBody());

                List<Object> hits = (List<Object>)response.get('results');

                SearchResult result = new SearchResult();
                result.query = req.query;
                result.matches = new List<String>();

                for (Object hit : hits) {
                    Map<String, Object> doc = (Map<String, Object>)hit;
                    result.matches.add((String)doc.get('content'));
                }

                results.add(result);
            }
        }

        return results;
    }

    public class SearchRequest {
        @InvocableVariable(required=true)
        public String query;
        @InvocableVariable
        public Integer maxResults = 10;
        @InvocableVariable
        public Map<String, String> filters;
    }

    public class SearchResult {
        @InvocableVariable
        public String query;
        @InvocableVariable
        public List<String> matches;
    }
}
```

## Hybrid Search (Pilot 2025)

Hybrid search combines semantic search with traditional keyword search for improved accuracy.

**Benefits:**
- Understands semantic similarities and context (semantic search)
- Recognizes company-specific words and concepts (keyword search)
- Higher accuracy than either method alone
- Handles acronyms, product codes, and technical terms better

### Use Case Example

```text
Service agent searches: "customer wants refund for SKU-12345"

Semantic Search finds:
- Return policy documents
- Refund procedures
- Customer satisfaction articles

Keyword Search finds:
- Specific SKU-12345 product documentation
- Previous cases mentioning SKU-12345
- Product-specific return windows

Hybrid Search combines both:
- Return procedures specifically for SKU-12345
- Previous refund cases for this product
- Product warranty terms
```

### Implementation

```apex
public class HybridSearchService {
    public static List<Map<String, Object>> hybridSearch(String query, Map<String, Object> filters) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:DataCloud/v1/search/hybrid');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');

        Map<String, Object> payload = new Map<String, Object>{
            'query' => query,
            'semantic' => new Map<String, Object>{
                'enabled' => true,
                'weight' => 0.6  // 60% semantic
            },
            'keyword' => new Map<String, Object>{
                'enabled' => true,
                'weight' => 0.4  // 40% keyword
            },
            'filters' => filters,
            'topK' => 20
        };

        req.setBody(JSON.serialize(payload));

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            return (List<Map<String, Object>>)response.get('results');
        }

        return new List<Map<String, Object>>();
    }
}
```

## Multi-Language Semantic Search

Vector database supports cross-language semantic search.

**Example:**
- Service agent types case subject in French: "Problème de connexion"
- Semantic search finds similar cases in English: "Login issues", "Connection problems", "Unable to access account"
- Returns relevant solutions regardless of language

**Configuration:**
```text
Data Cloud → Vector Database → Settings
- Enable multi-language support
- Supported languages: 100+ languages via multilingual embeddings
- Automatic language detection
- Cross-language similarity matching
```

## Use Cases for Vector Database

### 1. Customer Service Knowledge Retrieval

```apex
// Agentforce action: Find relevant knowledge articles
@InvocableMethod(label='Find Relevant Articles')
public static List<String> findRelevantArticles(List<String> customerQueries) {
    List<String> articles = new List<String>();

    for (String query : customerQueries) {
        List<SearchResult> results = SemanticSearchService.semanticSearch(
            new List<SearchRequest>{new SearchRequest(query, 5)}
        );

        if (!results.isEmpty()) {
            articles.addAll(results[0].matches);
        }
    }

    return articles;
}
```

### 2. Case Similarity Detection

```apex
public class CaseSimilarityService {
    public static List<Case> findSimilarCases(String caseDescription) {
        List<SearchResult> results = SemanticSearchService.semanticSearch(
            new List<SearchRequest>{new SearchRequest(caseDescription, 10)}
        );

        Set<Id> caseIds = new Set<Id>();
        // ... extract IDs from results

        return [SELECT Id, Subject, Description, Status, Resolution__c
                FROM Case
                WHERE Id IN :caseIds
                AND Status = 'Closed'
                ORDER BY ClosedDate DESC];
    }
}
```

### 3. Lead Scoring from Unstructured Data

```apex
public class LeadScoringService {
    public static Decimal scoreLeadFromContent(Id leadId) {
        List<EmailMessage> emails = [SELECT Id, TextBody
                                      FROM EmailMessage
                                      WHERE RelatedToId = :leadId];

        Decimal score = 0;
        String allContent = '';
        for (EmailMessage email : emails) {
            allContent += email.TextBody + ' ';
        }

        List<String> intentPhrases = new List<String>{
            'ready to purchase',
            'need pricing quote',
            'schedule demo',
            'implementation timeline'
        };

        for (String phrase : intentPhrases) {
            Decimal similarity = calculateSemanticSimilarity(allContent, phrase);
            score += similarity * 10;
        }

        return score;
    }
}
```
