FROM python:3.13

WORKDIR /app

COPY . .

COPY requirements.txt /requirements.txt

RUN pip install --no-cache-dir -r /requirements.txt

CMD ["python", "app.py"]
