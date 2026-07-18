FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY src/ ./src/
ENV PYTHONPATH=/app/src
EXPOSE 4318
CMD ["uvicorn", "codex_normalizer.main:app", "--host", "0.0.0.0", "--port", "4318"]
