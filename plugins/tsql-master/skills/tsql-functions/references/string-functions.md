# String Functions Reference

Complete reference for T-SQL string manipulation functions.

## Basic String Functions

### Character Functions
| Function | Description | Example |
|----------|-------------|---------|
| `ASCII(char)` | ASCII code of leftmost char | `SELECT ASCII('A')` -- 65 |
| `CHAR(int)` | Character from ASCII code | `SELECT CHAR(65)` -- 'A' |
| `UNICODE(char)` | Unicode code point | `SELECT UNICODE('A')` -- 65 |
| `NCHAR(int)` | Unicode character | `SELECT NCHAR(8364)` -- Euro sign |

### Length Functions
| Function | Description | Example |
|----------|-------------|---------|
| `LEN(string)` | Character count (no trailing spaces) | `SELECT LEN('Hello ')` -- 5 |
| `DATALENGTH(expr)` | Bytes used (includes trailing) | `SELECT DATALENGTH('Hello ')` -- 6 |

### Extraction Functions
| Function | Description | Example |
|----------|-------------|---------|
| `LEFT(string, n)` | Leftmost n characters | `SELECT LEFT('Hello', 2)` -- 'He' |
| `RIGHT(string, n)` | Rightmost n characters | `SELECT RIGHT('Hello', 2)` -- 'lo' |
| `SUBSTRING(str, start, len)` | Extract portion | `SELECT SUBSTRING('Hello', 2, 3)` -- 'ell' |

### Case Functions
| Function | Description | Example |
|----------|-------------|---------|
| `UPPER(string)` | Convert to uppercase | `SELECT UPPER('hello')` -- 'HELLO' |
| `LOWER(string)` | Convert to lowercase | `SELECT LOWER('HELLO')` -- 'hello' |

### Trimming Functions
| Function | Description | Version |
|----------|-------------|---------|
| `LTRIM(string)` | Remove leading spaces | All |
| `RTRIM(string)` | Remove trailing spaces | All |
| `TRIM([chars FROM] string)` | Remove both sides | 2017+ |
| `LTRIM(string, chars)` | Remove specific leading chars | 2022+ |
| `RTRIM(string, chars)` | Remove specific trailing chars | 2022+ |

```sql
-- SQL Server 2022 TRIM enhancements
SELECT TRIM('xy' FROM 'xxyHelloxyy')      -- 'Hello'
SELECT LTRIM('00012345', '0')              -- '12345'
SELECT RTRIM('Amount$$$', '$')             -- 'Amount'
```

## Search and Position Functions

### CHARINDEX
Find position of substring:
```sql
SELECT CHARINDEX('World', 'Hello World')           -- 7
SELECT CHARINDEX('o', 'Hello World', 5)            -- 8 (start from position 5)
SELECT CHARINDEX('xyz', 'Hello World')             -- 0 (not found)
```

### PATINDEX
Find position using pattern (supports wildcards):
```sql
SELECT PATINDEX('%[0-9]%', 'Test123')              -- 5 (first digit)
SELECT PATINDEX('%@%.%', 'user@domain.com')        -- 5 (email pattern)
SELECT PATINDEX('[A-Z]%', 'hello')                 -- 0 (doesn't start with uppercase)
```

## String Manipulation

### REPLACE
Replace all occurrences:
```sql
SELECT REPLACE('Hello World', 'World', 'Universe')  -- 'Hello Universe'
SELECT REPLACE('aaa', 'a', 'bb')                    -- 'bbbbbb'
```

### STUFF
Delete and insert at position:
```sql
-- STUFF(string, start, length_to_delete, insert_string)
SELECT STUFF('Hello', 2, 3, 'XYZ')                  -- 'HXYZo'
SELECT STUFF('1234567890', 4, 3, '-')               -- '123-7890'

-- Insert without deleting
SELECT STUFF('Hello', 3, 0, 'XXX')                  -- 'HeXXXllo'
```

### TRANSLATE (SQL 2017+)
Character-by-character replacement:
```sql
SELECT TRANSLATE('2*[3+4]', '[]', '()')             -- '2*(3+4)'
SELECT TRANSLATE('Hello', 'elo', 'axy')             -- 'Haxxy'
```

### REVERSE
Reverse a string:
```sql
SELECT REVERSE('Hello')                             -- 'olleH'

-- Check for palindrome
SELECT CASE WHEN LOWER(Name) = REVERSE(LOWER(Name))
       THEN 'Palindrome' ELSE 'Not' END
```

## Concatenation

### CONCAT (SQL 2012+)
NULL-safe concatenation:
```sql
-- Returns NULL if using + with NULL
SELECT 'Hello' + NULL + 'World'                     -- NULL

-- CONCAT treats NULL as empty string
SELECT CONCAT('Hello', NULL, 'World')               -- 'HelloWorld'
SELECT CONCAT(FirstName, ' ', LastName)
```

### CONCAT_WS (SQL 2017+)
Concatenate with separator (ignores NULLs):
```sql
SELECT CONCAT_WS(', ', 'Apple', NULL, 'Banana', 'Cherry')
-- Result: 'Apple, Banana, Cherry'

SELECT CONCAT_WS(' - ', City, State, Country)
```

### STRING_AGG (SQL 2017+)
Aggregate strings from multiple rows:
```sql
-- Basic aggregation
SELECT STRING_AGG(ProductName, ', ') AS Products
FROM Products

-- With ordering
SELECT CategoryID,
       STRING_AGG(ProductName, ', ') WITHIN GROUP (ORDER BY ProductName) AS Products
FROM Products
GROUP BY CategoryID

-- Pre-2017 alternative using FOR XML PATH
SELECT STUFF((
    SELECT ', ' + ProductName
    FROM Products
    FOR XML PATH(''), TYPE
).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS Products
```

## Splitting Strings

### STRING_SPLIT (SQL 2016+)
Split string into rows:
```sql
-- Basic split
SELECT value FROM STRING_SPLIT('apple,banana,cherry', ',')

-- With ordinal (SQL 2022+, requires compat level 160)
SELECT value, ordinal
FROM STRING_SPLIT('apple,banana,cherry', ',', 1)
ORDER BY ordinal

-- Join with split values
SELECT p.ProductID, p.ProductName
FROM Products p
WHERE p.ProductID IN (
    SELECT CAST(value AS INT)
    FROM STRING_SPLIT('1,5,10,15', ',')
)
```

## Formatting

### FORMAT (SQL 2012+)
Format using .NET format strings:
```sql
-- Numbers
SELECT FORMAT(123456.789, 'N2')                     -- '123,456.79'
SELECT FORMAT(123456.789, 'C', 'en-US')             -- '$123,456.79'
SELECT FORMAT(0.85, 'P0')                           -- '85%'

-- Dates
SELECT FORMAT(GETDATE(), 'yyyy-MM-dd')              -- '2024-01-15'
SELECT FORMAT(GETDATE(), 'MMMM dd, yyyy')           -- 'January 15, 2024'
SELECT FORMAT(GETDATE(), 'd', 'de-DE')              -- '15.01.2024'

-- Custom patterns
SELECT FORMAT(123, '00000')                         -- '00123'
SELECT FORMAT(1234567890, '(###) ###-####')         -- '(123) 456-7890'
```

**Performance Note:** FORMAT is slower than CONVERT for simple conversions.

### QUOTENAME
Add delimiters for identifiers:
```sql
SELECT QUOTENAME('My Table')                        -- '[My Table]'
SELECT QUOTENAME('My Table', '"')                   -- '"My Table"'
SELECT QUOTENAME('O''Brien')                        -- '[O'Brien]'

-- Dynamic SQL safety
DECLARE @TableName NVARCHAR(128) = 'Users'
EXEC('SELECT * FROM ' + QUOTENAME(@TableName))
```

## Phonetic Functions

### SOUNDEX
4-character phonetic code:
```sql
SELECT SOUNDEX('Smith')                             -- 'S530'
SELECT SOUNDEX('Smyth')                             -- 'S530'

-- Find similar names
SELECT * FROM Customers
WHERE SOUNDEX(LastName) = SOUNDEX('Smith')
```

### DIFFERENCE
Compare SOUNDEX values (0-4, higher = more similar):
```sql
SELECT DIFFERENCE('Smith', 'Smyth')                 -- 4 (very similar)
SELECT DIFFERENCE('Smith', 'Jones')                 -- 2 (less similar)

-- Fuzzy name matching
SELECT * FROM Customers
WHERE DIFFERENCE(LastName, 'Smith') >= 3
```

## Miscellaneous

### REPLICATE
Repeat a string:
```sql
SELECT REPLICATE('Ab', 3)                           -- 'AbAbAb'
SELECT REPLICATE('0', 5 - LEN(CAST(@Num AS VARCHAR))) + CAST(@Num AS VARCHAR)  -- Zero padding
```

### SPACE
Generate spaces:
```sql
SELECT 'Hello' + SPACE(10) + 'World'
SELECT REPLICATE(' ', 10)                           -- Equivalent
```

### STR
Convert number to string with formatting:
```sql
SELECT STR(123.456, 10, 2)                          -- '    123.46'
SELECT STR(123.456, 6, 1)                           -- ' 123.5'
```

### STRING_ESCAPE (SQL 2016+)
Escape special characters:
```sql
SELECT STRING_ESCAPE('Tab	here
newline', 'json')
-- Result: 'Tab\there\nnewline'
```

## Performance Considerations

1. **Avoid functions in WHERE clauses on indexed columns** - breaks SARGability
2. **Use CONCAT instead of + for NULL handling** - cleaner, safer
3. **FORMAT is slow** - use CONVERT with style codes for performance-critical code
4. **STRING_AGG is faster than FOR XML PATH** - use when available
5. **CHARINDEX vs LIKE** - CHARINDEX can be SARGable with careful use
