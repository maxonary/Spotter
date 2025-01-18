from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from sqlalchemy import create_engine, Column, Integer, String, Table, MetaData
from sqlalchemy.orm import sessionmaker
import requests

# Initialize FastAPI app
app = FastAPI()

# Database setup
DATABASE_URL = "sqlite:///./likers.db"  # Replace with your database URL
engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
metadata = MetaData()
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Define table for storing usernames
user_likes_table = Table(
    "user_likes",
    metadata,
    Column("id", Integer, primary_key=True, index=True),
    Column("media_id", String, index=True),
    Column("username", String, index=True),
)
metadata.create_all(bind=engine)

# Instagram Graph API details
INSTAGRAM_GRAPH_API_URL = "https://graph.instagram.com"
ACCESS_TOKEN = "YOUR_ACCESS_TOKEN"  # Replace with your actual access token

# Pydantic model for request body
class MediaRequest(BaseModel):
    media_id: str

@app.post("/fetch_likers/")
async def fetch_likers(media_request: MediaRequest):
    """
    Fetch users who liked the media and store their usernames in the database.
    """
    media_id = media_request.media_id
    url = f"{INSTAGRAM_GRAPH_API_URL}/{media_id}/likes?access_token={ACCESS_TOKEN}"
    
    try:
        # Fetch likers from Instagram API
        response = requests.get(url)
        if response.status_code != 200:
            raise HTTPException(
                status_code=response.status_code, detail=f"Error fetching likers: {response.text}"
            )
        
        likers = response.json().get("data", [])
        if not likers:
            return {"message": "No likes found for the given media ID."}
        
        # Save likers to database
        db = SessionLocal()
        for liker in likers:
            username = liker.get("username")
            if username:
                db.execute(user_likes_table.insert().values(media_id=media_id, username=username))
        db.commit()
        db.close()

        return {"message": f"Successfully fetched and stored {len(likers)} likers for media ID {media_id}."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/get_likers/{media_id}")
async def get_likers(media_id: str):
    """
    Retrieve usernames of users who liked the given media ID.
    """
    db = SessionLocal()
    try:
        result = db.execute(user_likes_table.select().where(user_likes_table.c.media_id == media_id)).fetchall()
        db.close()

        if not result:
            return {"message": "No likers found for the given media ID."}
        
        return {"media_id": media_id, "likers": [row["username"] for row in result]}
    except Exception as e:
        db.close()
        raise HTTPException(status_code=500, detail=str(e))