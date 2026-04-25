# LibraryDocumentation

This directory contains resources for generating library documentation locally, replicating the documentation available at [Documentation](https://build.openmodelica.org/Documentation/index.html).

## Table of Contents
- [Overview](#overview)
- [Key Files](#key-files)
- [Prerequisites](#prerequisites)
- [Usage Instructions](#usage-instructions)

## Overview
The resources in this directory allow users to generate library documentation locally using Docker. This includes building a Docker image, running scripts, and generating output files for documentation and icons.

## Key Files
- **Dockerfile**: Sets up a Docker image for generating the documentation.
- **run.ps1**: A PowerShell script that:
  - Builds the Docker image using openmodelica/openmodelica:v1.26.3-ompython.
  - Mounts the `GeneGenerateDoc.mos` and `generate_icons.py` files.
  - Creates an `Output` directory for all generated files.

## Prerequisites
Before using these resources, ensure you have the following installed:
- [Docker](https://www.docker.com/)
- [PowerShell](https://learn.microsoft.com/en-us/powershell/)

## Usage Instructions
1. Run the PowerShell script to build the Docker image and generate the documentation:
   ```powershell
   .\run.ps1
   ```
2. The generated documentation and icons will be available in the `Output` directory.



