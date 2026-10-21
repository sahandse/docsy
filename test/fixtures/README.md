# Docsy real-file smoke test fixtures

These are small, non-sensitive sample documents for manual testing with the actual Android system file picker.

- `sample_report.txt`: Persian UTF-8 text; verify it opens in Docsy's text preview.
- `sample_expenses.csv`: Persian UTF-8 CSV; verify it opens and the rows remain readable.

## Manual test with a real PDF

Use any ordinary, non-password-protected PDF stored on the phone. Choose it with **افزودن فایل**; confirm it appears in the library and opens in the in-app PDF viewer. Also test selecting multiple files, canceling the picker, and opening a large file. Office formats are handed off to another compatible app and are not rendered by Docsy itself.

The CI widget tests do not simulate Android's system picker or prove device-level file access. A physical-device run is required for that confirmation.