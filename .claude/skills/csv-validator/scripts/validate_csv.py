#!/usr/bin/env python3
"""
CSV Validator - Validates CSV files against a defined schema.

Usage:
    python validate_csv.py <csv_file> <schema_file> [options]

Options:
    --encoding ENCODING    CSV file encoding (default: utf-8)
    --delimiter DELIMITER  CSV delimiter (default: ,)
    --output FORMAT        Output format: text, json (default: text)
"""

import argparse
import csv
import json
import re
import sys
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any, Callable


@dataclass
class ValidationError:
    row: int
    column: str
    value: Any
    expected_type: str
    message: str


@dataclass
class ValidationResult:
    is_valid: bool
    total_rows: int
    errors: list[ValidationError] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)

    def to_dict(self) -> dict:
        return {
            "is_valid": self.is_valid,
            "total_rows": self.total_rows,
            "error_count": len(self.errors),
            "errors": [
                {
                    "row": e.row,
                    "column": e.column,
                    "value": e.value,
                    "expected_type": e.expected_type,
                    "message": e.message,
                }
                for e in self.errors
            ],
            "warnings": self.warnings,
        }


class TypeValidators:
    """Built-in type validators."""

    @staticmethod
    def string(value: str, min_len: int = 0, max_len: int = None, pattern: str = None) -> tuple[bool, str]:
        if not isinstance(value, str):
            return False, "Must be a string"
        if len(value) < min_len:
            return False, f"String length must be at least {min_len}"
        if max_len and len(value) > max_len:
            return False, f"String length must not exceed {max_len}"
        if pattern and not re.match(pattern, value):
            return False, f"String must match pattern: {pattern}"
        return True, ""

    @staticmethod
    def integer(value: str, min_val: int = None, max_val: int = None) -> tuple[bool, str]:
        try:
            int_val = int(value)
            if min_val is not None and int_val < min_val:
                return False, f"Value must be at least {min_val}"
            if max_val is not None and int_val > max_val:
                return False, f"Value must not exceed {max_val}"
            return True, ""
        except ValueError:
            return False, "Must be a valid integer"

    @staticmethod
    def float(value: str, min_val: float = None, max_val: float = None) -> tuple[bool, str]:
        try:
            float_val = float(value)
            if min_val is not None and float_val < min_val:
                return False, f"Value must be at least {min_val}"
            if max_val is not None and float_val > max_val:
                return False, f"Value must not exceed {max_val}"
            return True, ""
        except ValueError:
            return False, "Must be a valid number"

    @staticmethod
    def boolean(value: str) -> tuple[bool, str]:
        if value.lower() in ("true", "false", "1", "0", "yes", "no"):
            return True, ""
        return False, "Must be a boolean (true/false, 1/0, yes/no)"

    @staticmethod
    def date(value: str, format: str = "%Y-%m-%d") -> tuple[bool, str]:
        try:
            datetime.strptime(value, format)
            return True, ""
        except ValueError:
            return False, f"Must be a valid date in format: {format}"

    @staticmethod
    def datetime(value: str, format: str = "%Y-%m-%d %H:%M:%S") -> tuple[bool, str]:
        try:
            datetime.strptime(value, format)
            return True, ""
        except ValueError:
            return False, f"Must be a valid datetime in format: {format}"

    @staticmethod
    def email(value: str) -> tuple[bool, str]:
        pattern = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
        if re.match(pattern, value):
            return True, ""
        return False, "Must be a valid email address"

    @staticmethod
    def url(value: str) -> tuple[bool, str]:
        pattern = r"^https?://[^\s/$.?#].[^\s]*$"
        if re.match(pattern, value):
            return True, ""
        return False, "Must be a valid URL"

    @staticmethod
    def enum(value: str, values: list[str]) -> tuple[bool, str]:
        if value in values:
            return True, ""
        return False, f"Must be one of: {', '.join(values)}"

    @staticmethod
    def phone(value: str, pattern: str = r"^[\d\-\+\(\)\s]+$") -> tuple[bool, str]:
        if re.match(pattern, value):
            return True, ""
        return False, "Must be a valid phone number"


def load_schema(schema_path: Path) -> dict:
    """Load schema from JSON file."""
    with open(schema_path, "r", encoding="utf-8") as f:
        return json.load(f)


def get_validator(type_def: dict) -> Callable[[str], tuple[bool, str]]:
    """Get validator function based on type definition."""
    type_name = type_def.get("type", "string")
    constraints = {k: v for k, v in type_def.items() if k != "type"}

    validators = {
        "string": TypeValidators.string,
        "integer": TypeValidators.integer,
        "int": TypeValidators.integer,
        "float": TypeValidators.float,
        "number": TypeValidators.float,
        "boolean": TypeValidators.boolean,
        "bool": TypeValidators.boolean,
        "date": TypeValidators.date,
        "datetime": TypeValidators.datetime,
        "email": TypeValidators.email,
        "url": TypeValidators.url,
        "enum": TypeValidators.enum,
        "phone": TypeValidators.phone,
    }

    validator_func = validators.get(type_name, TypeValidators.string)

    def validate(value: str) -> tuple[bool, str]:
        return validator_func(value, **constraints)

    return validate


def validate_csv(
    csv_path: Path,
    schema: dict,
    encoding: str = "utf-8",
    delimiter: str = ",",
) -> ValidationResult:
    """Validate CSV file against schema."""
    errors = []
    warnings = []
    total_rows = 0

    fields = schema.get("fields", [])
    field_names = [f["name"] for f in fields]
    field_map = {f["name"]: f for f in fields}

    with open(csv_path, "r", encoding=encoding, newline="") as f:
        reader = csv.DictReader(f, delimiter=delimiter)

        # Validate headers
        if reader.fieldnames is None:
            return ValidationResult(
                is_valid=False,
                total_rows=0,
                errors=[
                    ValidationError(
                        row=0,
                        column="",
                        value="",
                        expected_type="",
                        message="CSV file is empty or has no headers",
                    )
                ],
            )

        actual_headers = list(reader.fieldnames)

        # Check for missing required headers
        missing_headers = set(field_names) - set(actual_headers)
        if missing_headers:
            errors.append(
                ValidationError(
                    row=0,
                    column="header",
                    value=str(actual_headers),
                    expected_type=str(field_names),
                    message=f"Missing required headers: {', '.join(missing_headers)}",
                )
            )

        # Check for extra headers
        extra_headers = set(actual_headers) - set(field_names)
        if extra_headers:
            warnings.append(f"Extra headers found (will be ignored): {', '.join(extra_headers)}")

        # Validate each row
        for row_num, row in enumerate(reader, start=2):  # Start at 2 (header is row 1)
            total_rows += 1

            for field_def in fields:
                col_name = field_def["name"]
                type_def = field_def.get("type_def", {"type": "string"})
                required = field_def.get("required", True)

                value = row.get(col_name, "")

                # Check required
                if required and (value is None or value.strip() == ""):
                    errors.append(
                        ValidationError(
                            row=row_num,
                            column=col_name,
                            value=value,
                            expected_type=type_def.get("type", "string"),
                            message="Required field is empty",
                        )
                    )
                    continue

                # Skip validation if optional and empty
                if not required and (value is None or value.strip() == ""):
                    continue

                # Type validation
                validator = get_validator(type_def)
                is_valid, error_msg = validator(value)
                if not is_valid:
                    errors.append(
                        ValidationError(
                            row=row_num,
                            column=col_name,
                            value=value,
                            expected_type=type_def.get("type", "string"),
                            message=error_msg,
                        )
                    )

    return ValidationResult(
        is_valid=len(errors) == 0,
        total_rows=total_rows,
        errors=errors,
        warnings=warnings,
    )


def format_output(result: ValidationResult, format: str = "text") -> str:
    """Format validation result for output."""
    if format == "json":
        return json.dumps(result.to_dict(), indent=2, ensure_ascii=False)

    # Text format
    lines = []
    lines.append("=" * 60)
    lines.append("CSV Validation Result")
    lines.append("=" * 60)
    lines.append(f"Status: {'✅ VALID' if result.is_valid else '❌ INVALID'}")
    lines.append(f"Total Rows: {result.total_rows}")
    lines.append(f"Errors: {len(result.errors)}")

    if result.warnings:
        lines.append("")
        lines.append("Warnings:")
        for warning in result.warnings:
            lines.append(f"  ⚠️  {warning}")

    if result.errors:
        lines.append("")
        lines.append("Errors:")
        for error in result.errors[:50]:  # Show first 50 errors
            lines.append(f"  Row {error.row}, Column '{error.column}':")
            lines.append(f"    Value: {repr(error.value)}")
            lines.append(f"    Error: {error.message}")
        if len(result.errors) > 50:
            lines.append(f"  ... and {len(result.errors) - 50} more errors")

    lines.append("=" * 60)
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Validate CSV files against a schema")
    parser.add_argument("csv_file", help="Path to the CSV file to validate")
    parser.add_argument("schema_file", help="Path to the JSON schema file")
    parser.add_argument("--encoding", default="utf-8", help="CSV file encoding")
    parser.add_argument("--delimiter", default=",", help="CSV delimiter")
    parser.add_argument("--output", choices=["text", "json"], default="text", help="Output format")

    args = parser.parse_args()

    csv_path = Path(args.csv_file)
    schema_path = Path(args.schema_file)

    if not csv_path.exists():
        print(f"Error: CSV file not found: {csv_path}", file=sys.stderr)
        sys.exit(1)

    if not schema_path.exists():
        print(f"Error: Schema file not found: {schema_path}", file=sys.stderr)
        sys.exit(1)

    schema = load_schema(schema_path)
    result = validate_csv(csv_path, schema, args.encoding, args.delimiter)

    print(format_output(result, args.output))
    sys.exit(0 if result.is_valid else 1)


if __name__ == "__main__":
    main()
