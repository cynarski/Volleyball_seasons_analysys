FROM python:3.13

WORKDIR /app

COPY . /app/

COPY ../requirements.txt /requirements.txt

RUN pip install --no-cache-dir -r /requirements.txt

#RUN #chmod +x /check_db.py


CMD ["python", "app.py"]
