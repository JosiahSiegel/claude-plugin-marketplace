# T-SQL Master

Comprehensive T-SQL and SQL Server expertise for query optimization, performance tuning, and Azure SQL Database.

## Features

- **Progressive Disclosure Skills** - Deep knowledge organized for efficient loading
- **Expert Agent** - Conversational T-SQL optimization assistance
- **Optimization Commands** - Automated query and index analysis
- **Diagnostic Scripts** - Ready-to-use SQL Server health checks

## Installation

### From Marketplace (Recommended)

```bash
/plugin marketplace add JosiahSiegel/claude-plugin-marketplace
/plugin install tsql-master@JosiahSiegel
```

### Local Installation

```bash
git clone https://github.com/JosiahSiegel/claude-plugin-marketplace.git
cp -r claude-plugin-marketplace/plugins/tsql-master ~/.claude/plugins/local/
```

## Usage

Just ask about T-SQL optimization:

- "Optimize this query for better performance"
- "What indexes should I create for this table?"
- "Help me understand this execution plan"
- "How do I fix parameter sniffing?"
- "Best practices for Azure SQL Database"

## Components

### Agent

| Name | Purpose |
|------|---------|
| `tsql-expert` | Primary expert for T-SQL optimization and SQL Server performance |

### Skills

| Skill | Purpose |
|-------|---------|
| `tsql-functions` | Complete T-SQL function reference (string, date, window, JSON, XML) |
| `query-optimization` | SARGability, joins, hints, statistics, execution plans |
| `index-strategies` | Clustered, nonclustered, columnstore, filtered indexes |
| `azure-sql-optimization` | Azure SQL Database features, DTU/vCore, Hyperscale |
| `advanced-patterns` | CTEs, APPLY, MERGE, temporal tables, In-Memory OLTP |

### Commands

| Command | Purpose |
|---------|---------|
| `/analyze-query` | Analyze query for optimization opportunities |
| `/suggest-indexes` | Recommend indexes for query patterns |
| `/explain-plan` | Help interpret execution plan operators |

### Scripts

| Script | Purpose |
|--------|---------|
| `check-sargability.sql` | Find queries with SARGability issues |
| `index-analysis.sql` | Comprehensive index health check |

## SQL Server Version Support

| Version | Compatibility Level | Key Features |
|---------|---------------------|--------------|
| SQL Server 2016 | 130 | Query Store, JSON, Temporal Tables |
| SQL Server 2017 | 140 | STRING_AGG, Adaptive Joins, TRIM |
| SQL Server 2019 | 150 | Batch Mode on Rowstore, Scalar UDF Inlining |
| SQL Server 2022 | 160 | GREATEST/LEAST, DATETRUNC, GENERATE_SERIES, PSP |
| Azure SQL Database | Latest | Automatic Tuning, Hyperscale, Serverless |

## Key Optimization Topics

### Query Performance
- SARGable query patterns
- Join optimization (LOOP, MERGE, HASH)
- Query hints (RECOMPILE, OPTIMIZE FOR, MAXDOP)
- Parameter sniffing solutions
- Statistics and cardinality estimation

### Index Strategy
- Clustered index key selection
- Covering indexes with INCLUDE
- Filtered indexes for specific patterns
- Columnstore for analytics
- Index maintenance and fragmentation

### Azure SQL Database
- DTU vs vCore selection
- Automatic tuning
- Query Performance Insight
- Hyperscale architecture
- Serverless configuration

### Advanced Patterns
- Recursive CTEs for hierarchies
- CROSS/OUTER APPLY techniques
- MERGE for upsert operations
- Window functions and framing
- In-Memory OLTP tables

## Plugin Structure

```
tsql-master/
├── .claude-plugin/
│   └── plugin.json
├── agents/
│   └── tsql-expert.md
├── skills/
│   ├── tsql-functions/
│   │   ├── SKILL.md
│   │   └── references/
│   ├── query-optimization/
│   │   ├── SKILL.md
│   │   └── references/
│   ├── index-strategies/
│   │   ├── SKILL.md
│   │   └── references/
│   ├── azure-sql-optimization/
│   │   ├── SKILL.md
│   │   └── references/
│   └── advanced-patterns/
│       ├── SKILL.md
│       └── references/
├── commands/
│   ├── analyze-query.md
│   ├── suggest-indexes.md
│   └── explain-plan.md
├── scripts/
│   ├── check-sargability.sql
│   ├── index-analysis.sql
│   └── README.md
└── README.md
```

## What's New in 2.0.0

- **Progressive disclosure skills** - Knowledge organized into lean SKILL.md files with detailed references
- **Restructured agent** - Proper example blocks and tool configuration
- **New commands** - `/analyze-query`, `/suggest-indexes`, `/explain-plan`
- **Diagnostic scripts** - SQL scripts for SARGability and index analysis
- **Enhanced Azure SQL coverage** - Hyperscale, serverless, automatic tuning
- **SQL Server 2022 features** - GENERATE_SERIES, DATETRUNC, PSP optimization

## Technical Details

- **Version:** 2.0.0
- **Author:** Josiah Siegel
- **License:** MIT
- **Repository:** https://github.com/JosiahSiegel/claude-plugin-marketplace

## Support

- [GitHub Issues](https://github.com/JosiahSiegel/claude-plugin-marketplace/issues)
- [Microsoft SQL Server Documentation](https://learn.microsoft.com/en-us/sql/sql-server/)
