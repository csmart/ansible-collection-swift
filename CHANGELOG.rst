================================
csmart.swift Release Notes
================================

.. contents:: Topics

v0.1.0
======

Major Changes
-------------

- Migrated from standalone Ansible role to Ansible collection format.
- Updated all modules to use fully qualified collection names (FQCNs).
- Bumped minimum Ansible version to 2.15.
- Added EL 9 platform support.
- Replaced ``with_items`` with ``loop`` throughout.
- Normalized all boolean values to ``true``/``false``.
- Added Molecule testing framework with default scenario.
- Added yamllint and ansible-lint configuration.
- Added GitHub Actions CI workflow.
- Included playbooks from the separate swift-ansible repository.
- Added sample inventory and test script.
- Replaced Travis CI with GitHub Actions.

v1.0.0
======

- Initial release as standalone Ansible role.
