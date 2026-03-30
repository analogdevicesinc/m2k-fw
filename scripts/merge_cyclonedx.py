#!/usr/bin/env python3
"""Generate or merge CycloneDX SBOMs.

Can either merge extra components into an existing CycloneDX SBOM, or generate
a standalone SBOM from --extra-pkg arguments alone.

Usage (merge):
    python3 scripts/merge_cyclonedx.py \
        -i build/buildroot.cdx.json \
        --extra-pkg linux,v6.12,GPL-2.0-only,https://github.com/analogdevicesinc/linux.git \
        -o build/plutosdr-fw.cdx.json

Usage (standalone):
    python3 scripts/merge_cyclonedx.py \
        --project-name linux --project-version v6.12 \
        --extra-pkg linux,v6.12,GPL-2.0-only,https://github.com/analogdevicesinc/linux.git \
        -o build/linux.cdx.json
"""

import argparse
import json
import sys
import uuid
from datetime import datetime, timezone


def parse_extra_pkg(value):
    parts = value.split(",", 3)
    if len(parts) != 4:
        raise argparse.ArgumentTypeError(
            f"expected name,version,license,url but got: {value}")
    return {"name": parts[0], "version": parts[1],
            "license": parts[2], "url": parts[3]}


def make_component(epkg):
    component = {
        "bom-ref": epkg["name"],
        "type": "firmware",
        "name": epkg["name"],
        "version": epkg["version"],
    }

    if epkg["license"] and epkg["license"] != "NOASSERTION":
        component["licenses"] = [{"license": {"id": epkg["license"]}}]

    if epkg["url"]:
        component["externalReferences"] = [{
            "type": "vcs",
            "url": epkg["url"],
        }]

    return component


def new_cdx_doc(project_name, project_version):
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    return {
        "bomFormat": "CycloneDX",
        "specVersion": "1.6",
        "serialNumber": f"urn:uuid:{uuid.uuid4()}",
        "version": 1,
        "metadata": {
            "timestamp": now,
            "component": {
                "bom-ref": project_name,
                "name": project_name,
                "version": project_version,
                "type": "firmware",
            },
            "tools": {
                "components": [{
                    "type": "application",
                    "name": "plutosdr-fw-sbom-generator",
                    "version": "1.0.0",
                }],
            },
        },
        "components": [],
        "dependencies": [{
            "ref": project_name,
            "dependsOn": [],
        }],
    }


def main():
    parser = argparse.ArgumentParser(
        description="Generate or merge CycloneDX SBOMs.")
    parser.add_argument("-i", "--in-file", type=argparse.FileType("r"),
                        default=None)
    parser.add_argument("-o", "--out-file", nargs="?",
                        type=argparse.FileType("w"), default=sys.stdout)
    parser.add_argument("--project-name", type=str, default="buildroot")
    parser.add_argument("--project-version", type=str, default="unknown")
    parser.add_argument("--extra-pkg", type=parse_extra_pkg, action="append",
                        default=[],
                        help="name,version,license,download-url")
    args = parser.parse_args()

    if args.in_file:
        doc = json.load(args.in_file)
    else:
        doc = new_cdx_doc(args.project_name, args.project_version)

    for epkg in args.extra_pkg:
        doc["components"].append(make_component(epkg))
        for dep in doc.get("dependencies", []):
            if dep.get("ref") == doc.get("metadata", {}).get("component", {}).get("bom-ref"):
                dep["dependsOn"].append(epkg["name"])
                break

    json.dump(doc, args.out_file, indent=2)
    args.out_file.write("\n")


if __name__ == "__main__":
    main()
