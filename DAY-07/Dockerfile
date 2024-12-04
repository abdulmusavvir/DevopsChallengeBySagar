FROM python:3-slim AS build
WORKDIR /app
COPY DAY-07/app/requirements.txt /app/requirements.txt
COPY DAY-07/app/flaskr /app/flaskr
COPY DAY-07/app/instance /app/instance
COPY DAY-07/app/tests  /app/tests
RUN pip install --no-cache-dir -r /app/requirements.txt
ENV FLASK_APP=flaskr
ENV FLASK_RUN_HOST=0.0.0.0
ENV PYTHONPATH=/app
EXPOSE 5000
RUN flask --app flaskr init-db
CMD ["flask", "--app", "flaskr", "run", "--debug"]