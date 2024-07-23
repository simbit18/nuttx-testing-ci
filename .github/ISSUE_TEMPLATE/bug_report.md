name: Bug Report
description: Submit a bug report.
labels: [bug]
body:
  - type: textarea
    attributes:
      label: Description / Steps to reproduce the issue
      description: A clear and concise description of what the bug is, and why you consider it to be a bug, and steps for how to reproduce it
      placeholder: |
        A description with steps to reproduce the issue.
        1. Step 1
        2. Step 2
    validations:
      required: true

  - type: textarea
    attributes:
      label: Expected behavior
      description: A description of what you expected to happen.
    validations:
      required: true

  - type: textarea
    attributes:
      label: Actual behavior
      description: A description of what is actually happening.
    validations:
      required: true

  - type: checkboxes
    attributes:
      label: Verification
      description: Please verify that you've followed these steps.
      options:
        - label: I have verified that my NuttX is up-to-date before submitting the report.
          required: true

  - type: input
    attributes:
      label: NuttX Version + OS
      description: Please run `uname`.
      placeholder: "Ver (12.5.1) + OS (Linux, Darwin, Msys2, ecc)"
    validations:
      required: true

  - type: input
    attributes:
      label: Are you willing to submit a PR?
      description: We accept contributions!
