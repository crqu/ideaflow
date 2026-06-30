#!/usr/bin/env python3
"""
IdeaFlow eval harness — static analysis scoring.

Since we can't run xcodebuild without Xcode, this eval focuses on:
- File existence (project structure)
- Swift anti-pattern detection
- Lint output parsing (if swiftlint available)
- Test file coverage

Output: JSON with scores for factory system.
"""

import json
import os
import re
import subprocess
import sys
from pathlib import Path


def find_swift_files(root: Path) -> list[Path]:
    """Find all .swift files in the project."""
    swift_files = []
    for pattern in ["IdeaFlow/**/*.swift", "IdeaFlowWatch/**/*.swift", "Shared/**/*.swift"]:
        swift_files.extend(root.glob(pattern))
    return swift_files


def check_file_existence(root: Path) -> dict:
    """Check that expected project files exist."""
    expected_files = [
        # Phase 1: Project scaffold
        "project.yml",
        "CLAUDE.md",
        "factory.md",
        "IdeaFlow/IdeaFlowApp.swift",
        "IdeaFlow/Views/ContentView.swift",
        "IdeaFlowWatch/IdeaFlowWatchApp.swift",
        "IdeaFlowWatch/Views/ContentView.swift",
        "Shared/Models/VoiceNote.swift",
        # Phase 2: Shared data models + utilities
        "Shared/Models/ClaudeResponse.swift",
        "Shared/Utilities/KeychainHelper.swift",
        "Shared/Utilities/DateFormatters.swift",
        "Shared/Utilities/Logger.swift",
        "Tests/SharedTests/VoiceNoteTests.swift",
        "Tests/SharedTests/DateFormattersTests.swift",
        "Tests/SharedTests/ClaudeResponseTests.swift",
        # Phase 3: iOS companion app services and views
        "IdeaFlow/Services/ClaudeClient.swift",
        "IdeaFlow/Services/ObsidianWriter.swift",
        "IdeaFlow/Services/NoteProcessor.swift",
        "IdeaFlow/ViewModels/NotesViewModel.swift",
        "IdeaFlow/Views/SettingsView.swift",
        "IdeaFlow/Views/NoteListView.swift",
        "IdeaFlow/Views/NoteDetailView.swift",
        "Tests/IdeaFlowTests/ClaudeClientTests.swift",
        "Tests/IdeaFlowTests/ObsidianWriterTests.swift",
    ]

    existing = []
    missing = []

    for f in expected_files:
        if (root / f).exists():
            existing.append(f)
        else:
            missing.append(f)

    return {
        "existing": existing,
        "missing": missing,
        "score": len(existing) / len(expected_files) if expected_files else 0.0,
    }


def check_anti_patterns(swift_files: list[Path]) -> dict:
    """Check for Swift anti-patterns."""
    issues = []

    for filepath in swift_files:
        content = filepath.read_text()
        lines = content.splitlines()

        for i, line in enumerate(lines, 1):
            if re.search(r'let\s+apiKey\s*=\s*"[^"]+"', line, re.IGNORECASE):
                issues.append({
                    "file": str(filepath),
                    "line": i,
                    "issue": "hardcoded_api_key",
                    "severity": "error",
                })

            if re.search(r'sk-ant-[a-zA-Z0-9-]+', line):
                issues.append({
                    "file": str(filepath),
                    "line": i,
                    "issue": "exposed_anthropic_key",
                    "severity": "error",
                })

            force_unwrap_match = re.search(r'[a-zA-Z_]\w*!(?!\s*=)', line)
            if force_unwrap_match and "IBOutlet" not in line and "@IBOutlet" not in line:
                issues.append({
                    "file": str(filepath),
                    "line": i,
                    "issue": "force_unwrap",
                    "severity": "warning",
                })

    error_count = sum(1 for i in issues if i["severity"] == "error")
    warning_count = sum(1 for i in issues if i["severity"] == "warning")

    if error_count > 0:
        score = 0.0
    elif warning_count > 5:
        score = 0.5
    elif warning_count > 0:
        score = 0.8
    else:
        score = 1.0

    return {
        "issues": issues,
        "error_count": error_count,
        "warning_count": warning_count,
        "score": score,
    }


def run_swiftlint(root: Path) -> dict:
    """Run swiftlint if available."""
    try:
        result = subprocess.run(
            ["swiftlint", "lint", "--reporter", "json"],
            cwd=root,
            capture_output=True,
            text=True,
            timeout=60,
        )

        if result.returncode == 127:
            return {"available": False, "score": None, "skipped": True}

        try:
            violations = json.loads(result.stdout) if result.stdout else []
        except json.JSONDecodeError:
            violations = []

        errors = sum(1 for v in violations if v.get("severity") == "error")
        warnings = sum(1 for v in violations if v.get("severity") == "warning")

        if errors > 0:
            score = 0.3
        elif warnings > 10:
            score = 0.6
        elif warnings > 0:
            score = 0.8
        else:
            score = 1.0

        return {
            "available": True,
            "errors": errors,
            "warnings": warnings,
            "score": score,
        }

    except FileNotFoundError:
        return {"available": False, "score": None, "skipped": True}
    except subprocess.TimeoutExpired:
        return {"available": True, "score": 0.5, "timeout": True}


def count_files(root: Path) -> dict:
    """Count Swift and test files."""
    swift_files = find_swift_files(root)
    test_files = list(root.glob("**/Tests/**/*.swift")) + list(root.glob("**/*Tests.swift"))

    return {
        "swift_files": len(swift_files),
        "test_files": len(test_files),
        "test_coverage_ratio": len(test_files) / len(swift_files) if swift_files else 0.0,
    }


def main():
    root = Path(__file__).parent.parent

    swift_files = find_swift_files(root)

    file_check = check_file_existence(root)
    anti_patterns = check_anti_patterns(swift_files)
    lint_result = run_swiftlint(root)
    file_counts = count_files(root)

    capability_score = file_check["score"]
    if capability_score >= 0.8:
        capability_score = min(1.0, 0.1 + (file_counts["swift_files"] * 0.02))

    scores = {
        "capability_surface": round(capability_score, 2),
        "lint": lint_result["score"] if lint_result.get("score") is not None else anti_patterns["score"],
        "tests": round(file_counts["test_coverage_ratio"], 2),
        "type_check": 1.0 if file_check["score"] == 1.0 else 0.5,
        "observability": 0.0,
    }

    report = {
        "scores": scores,
        "details": {
            "file_existence": file_check,
            "anti_patterns": anti_patterns,
            "lint": lint_result,
            "file_counts": file_counts,
        },
        "summary": {
            "total_swift_files": file_counts["swift_files"],
            "missing_files": len(file_check["missing"]),
            "anti_pattern_errors": anti_patterns["error_count"],
            "swiftlint_available": lint_result.get("available", False),
        },
    }

    print(json.dumps(report, indent=2))

    if anti_patterns["error_count"] > 0 or file_check["score"] < 0.5:
        sys.exit(1)

    sys.exit(0)


if __name__ == "__main__":
    main()
