from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import StreamingResponse
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from starlette.responses import Response
import boto3
import os
import io
import time

app = FastAPI()

# Prometheus metrics
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint'])
REQUEST_DURATION = Histogram('http_request_duration_seconds', 'HTTP request duration')

# S3 configuration (MinIO)
s3_client = boto3.client(
    's3',
    endpoint_url=os.getenv('S3_ENDPOINT', 'http://minio:9000'),
    aws_access_key_id=os.getenv('S3_ACCESS_KEY', 'minioadmin'),
    aws_secret_access_key=os.getenv('S3_SECRET_KEY', 'minioadmin'),
)

BUCKET_NAME = os.getenv('S3_BUCKET', 'images')

@app.on_event("startup")
async def startup_event():
    try:
        s3_client.create_bucket(Bucket=BUCKET_NAME)
    except Exception as e:
        print(f"Bucket might already exist: {e}")

@app.get("/health/live")
async def liveness():
    return {"status": "alive"}

@app.get("/health/ready")
async def readiness():
    try:
        s3_client.list_buckets()
        return {"status": "ready"}
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Not ready: {str(e)}")

@app.get("/metrics")
async def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)

@app.post("/upload")
async def upload_image(file: UploadFile = File(...)):
    REQUEST_COUNT.labels(method='POST', endpoint='/upload').inc()
    start_time = time.time()
    
    try:
        contents = await file.read()
        s3_client.put_object(
            Bucket=BUCKET_NAME,
            Key=file.filename,
            Body=contents,
            ContentType=file.content_type
        )
        
        REQUEST_DURATION.observe(time.time() - start_time)
        return {
            "filename": file.filename,
            "size": len(contents),
            "message": "File uploaded successfully"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/download/{filename}")
async def download_image(filename: str):
    REQUEST_COUNT.labels(method='GET', endpoint='/download').inc()
    
    try:
        response = s3_client.get_object(Bucket=BUCKET_NAME, Key=filename)
        return StreamingResponse(
            io.BytesIO(response['Body'].read()),
            media_type=response['ContentType']
        )
    except Exception as e:
        raise HTTPException(status_code=404, detail=f"File not found: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)