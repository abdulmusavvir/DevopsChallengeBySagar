FROM python:3-slim AS build
WORKDIR /app
COPY app/requirements.txt ./
COPY app/flaskr /app/flaskr
COPY app/instance /app/instance
COPY app/tests  /app/tests
RUN pip install --no-cache-dir -r requirements.txt
ENV FLASK_APP=flaskr
ENV FLASK_RUN_HOST=0.0.0.0
ENV PYTHONPATH=/app
EXPOSE 5000
RUN flask --app flaskr init-db
CMD ["flask", "--app", "flaskr", "run", "--debug"]