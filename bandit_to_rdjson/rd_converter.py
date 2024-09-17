import json
import os
import sys
from typing import Any, Dict, TextIO

def get_severity(issue_severity: str) -> str:
    """Map Bandit issue severity to RDJSON severity."""
    severity_mapping = {
        "LOW": "INFO",
        "MEDIUM": "WARNING",
        "HIGH": "ERROR"
    }
    return severity_mapping.get(issue_severity.upper(), "WARNING")

def format_message(test_id: str, issue_text: str, code: str, more_info: str) -> str:
    """Format the diagnostic message."""
    return (
        f"<{test_id}> {issue_text}\n\n"
        f"`{code}`\n\n"
        f"{more_info}"
    )

def bandit_to_rdjson(jsonin: TextIO) -> str:
    """Convert Bandit JSON format to RDJSON format."""
    bandit_data: Dict[str, Any] = json.load(jsonin)
    tool_name: str = os.getenv("INPUT_TOOL_NAME", "bandit")

    if "results" not in bandit_data:
        raise RuntimeError("This doesn't look like a valid Bandit JSON")

    rdjson: Dict[str, Any] = {
        "source": {
            "name": tool_name,
            "url": "https://github.com/PyCQA/bandit"
        },
        "severity": "WARNING",  # Default severity
        "diagnostics": []
    }

    for result in bandit_data["results"]:
        message = format_message(
            test_id=result["test_id"],
            issue_text=result["issue_text"],
            code=result["code"],
            more_info=result.get("more_info", "")
        )
        severity = get_severity(result["issue_severity"])

        rdjson["diagnostics"].append({
            "message": message,
            "severity": severity,
            "location": {
                "path": result["filename"],
                "range": {
                    "start": {
                        "line": result["line_number"],
                        "column": result["col_offset"] + 1  # col_offset is zero-based
                    },
                    "end": {
                        "line": result["line_number"],  # Bandit does not provide end line, assuming single line
                        "column": result["end_col_offset"] + 1  # Adjusting for zero-based offset
                    }
                }
            }
        })

    return json.dumps(rdjson, indent=2)

if __name__ == "__main__":
    print(bandit_to_rdjson(sys.stdin))
