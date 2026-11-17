# Local preview of the documentation site.
# The PowerShell toolkit targets Windows and is tested on Windows runners in CI,
# so it is not part of this image.
FROM python:3.12-slim

WORKDIR /docs

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

# Build once in strict mode (fails on broken links), then serve with live reload.
CMD ["sh", "-c", "mkdocs build --strict && mkdocs serve --dev-addr 0.0.0.0:8000"]
