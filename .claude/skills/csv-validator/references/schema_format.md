# Schema Format Reference

## Schema Structure

```json
{
  "name": "schema_name",
  "description": "Schema description",
  "fields": [
    {
      "name": "column_name",
      "type_def": { "type": "string" },
      "required": true
    }
  ]
}
```

## Supported Types and Constraints

### string
```json
{"type": "string", "min_len": 1, "max_len": 100, "pattern": "^[A-Z].*"}
```

### integer / int
```json
{"type": "integer", "min_val": 0, "max_val": 100}
```

### float / number
```json
{"type": "float", "min_val": 0.0, "max_val": 1.0}
```

### boolean / bool
Accepts: `true`, `false`, `1`, `0`, `yes`, `no`
```json
{"type": "boolean"}
```

### date
```json
{"type": "date", "format": "%Y-%m-%d"}
```

### datetime
```json
{"type": "datetime", "format": "%Y-%m-%d %H:%M:%S"}
```

### email
```json
{"type": "email"}
```

### url
```json
{"type": "url"}
```

### enum
```json
{"type": "enum", "values": ["active", "inactive", "pending"]}
```

### phone
```json
{"type": "phone", "pattern": "^\\d{3}-\\d{4}-\\d{4}$"}
```

## Complete Example Schema

```json
{
  "name": "user_data",
  "description": "User registration data schema",
  "fields": [
    {
      "name": "id",
      "type_def": {"type": "integer", "min_val": 1},
      "required": true
    },
    {
      "name": "email",
      "type_def": {"type": "email"},
      "required": true
    },
    {
      "name": "name",
      "type_def": {"type": "string", "min_len": 1, "max_len": 100},
      "required": true
    },
    {
      "name": "age",
      "type_def": {"type": "integer", "min_val": 0, "max_val": 150},
      "required": true
    },
    {
      "name": "status",
      "type_def": {"type": "enum", "values": ["active", "inactive"]},
      "required": true
    },
    {
      "name": "created_at",
      "type_def": {"type": "datetime", "format": "%Y-%m-%d %H:%M:%S"},
      "required": true
    }
  ]
}
```

## Japanese Date Formats

Common patterns for Japanese systems:
- `%Y年%m月%d日` → 2024年01月15日
- `%Y/%m/%d` → 2024/01/15
- `%H時%M分%S秒` → 14時30分00秒
