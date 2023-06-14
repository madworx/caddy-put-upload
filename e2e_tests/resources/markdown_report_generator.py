#!/usr/bin/env python3
"""
This script generates a Markdown report from an XML report file.

Usage:
    python markdown_report_generator.py report_file markdown_file [--link_base LINK_BASE]

Arguments:
    report_file (str): Path to the XML report file.
    markdown_file (str): Path to the output Markdown file.

Optional Argument:
    --link_base (str): Base URL for links in the Markdown report.
                       If provided, the "Links" column will be added to the report with links
                       to the coverage report and coverage file.
"""

import argparse
import re
from datetime import datetime
from typing import Dict, List

import xmltodict


def parse_xml(filename: str, link_base: str = None) -> List[Dict[str, str]]:
    """
    Parse the XML report file and extract relevant information.

    Args:
        filename: Path to the XML report file.
        link_base: Base URL for links.

    Returns:
        A list of dictionaries representing test suite results.
    """
    with open(filename, encoding="UTF-8") as xml_file:
        data_dict = xmltodict.parse(xml_file.read())

    # Get suites data
    suites = data_dict["robot"]["suite"]["suite"]
    results = []

    # Loop through each suite to extract the relevant information
    for suite in suites:
        result = {}

        # Extract suite name
        result["Suite"] = suite["@name"]

        # Determine suite status and format it appropriately
        suite_status = suite["status"]["@status"]
        result["Status"] = "✅ Passed" if suite_status == "PASS" else "🔴 Failed"

        # Extract code coverage information
        if "meta" in suite:
            result["Code coverage"] = re.search(r"\d+.\d%", suite["meta"]["#text"]).group()
        else:
            result["Code coverage"] = "N/A"

        # Extract test results
        tests = suite["test"]
        # Ensure 'tests' is always a list
        if isinstance(tests, dict):
            tests = [tests]

        result["Passed"] = len([test for test in tests if test["status"]["@status"] == "PASS"])
        result["Failed"] = len([test for test in tests if test["status"]["@status"] == "FAIL"])
        result["Skipped"] = len([test for test in tests if test["status"]["@status"] == "SKIP"])

        # Calculate test duration
        start_time = datetime.strptime(suite["status"]["@starttime"], "%Y%m%d %H:%M:%S.%f")
        end_time = datetime.strptime(suite["status"]["@endtime"], "%Y%m%d %H:%M:%S.%f")
        duration = (end_time - start_time).total_seconds()
        result["Time duration"] = str(duration) + "s"

        # If link_base is provided and code coverage is not N/A, create links
        if link_base and result["Code coverage"] != "N/A":
            source_filename = re.sub(r"\.robot", "", suite["@source"].split("/")[-1])
            result["Links"] = (
                f"[Report]({link_base}/{source_filename}.coverage.html), "
                f"[Coverage]({link_base}/{source_filename}.coverage)"
            )

        results.append(result)

    return results


def generate_markdown(data: List[Dict[str, str]], output_file: str, link_base: str = None):
    """
    Generate a Markdown report from the provided data and save it to the output file.

    Args:
        data: Test suite results data.
        output_file: Path to the output Markdown file.
    """
    with open(output_file, "w", encoding="UTF-8") as markdown:
        markdown.write("# Execution summary\n\n")

        headers = {key: True for row in data for key in row}

        if link_base:
            markdown.write(f"[Full execution logs]({link_base}/log.html)\n\n")

        # Write table headers
        markdown.write("| " + " | ".join(headers) + " |\n")
        markdown.write("| " + " | ".join(["---"] * len(headers)) + " |\n")

        # Write each row of data
        for i, result in enumerate(data):
            # If it's the last row, make it bold
            if i == len(data) - 1:
                markdown.write(
                    "| " + " | ".join("**" + str(result.get(header, "")) + "**" for header in headers) + " |\n"
                )
            else:
                markdown.write("| " + " | ".join(str(result.get(header, "")) for header in headers) + " |\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate Markdown from XML report")

    # Define arguments
    parser.add_argument("report_file", help="Path to the report file")
    parser.add_argument("markdown_file", help="Path to the output Markdown file")
    parser.add_argument("--link_base", help="Base URL for links", default=None)

    args = parser.parse_args()

    # Extract arguments
    report_file = args.report_file
    markdown_file = args.markdown_file

    # Try to generate markdown, handle errors appropriately
    try:
        markdown_data = parse_xml(report_file, args.link_base)
        generate_markdown(markdown_data, markdown_file, args.link_base)
        print("Markdown generated successfully!")
    except FileNotFoundError:
        print(f"Error: The report file '{report_file}' does not exist.")
    except Exception as e:  # pylint: disable=broad-except
        print(f"Unexpected error: {e}")
