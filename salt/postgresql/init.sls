postgresql:
  pkg:
    - installed
  service:
    - running
    - require:
      - pkg: postgresql
