from fastapi import FastAPI, Query, HTTPException
from pydantic import BaseModel
from pymongo import MongoClient
from geopy.geocoders import Nominatim
from geopy.exc import GeocoderTimedOut
from geopy.distance import geodesic
from typing import List, Dict, Optional
import os
from dotenv import load_dotenv

load_dotenv()

# MongoDB Configuration
MONGO_URI = os.getenv("MONGO_URI")  # Replace with your MongoDB URI
DB_NAME = "LinkLocationDB"
COLLECTION_NAME = "links"

# FastAPI Instance
app = FastAPI()

# MongoDB Connection
client = MongoClient(MONGO_URI)
db = client[DB_NAME]
collection = db[COLLECTION_NAME]

# Geolocation Helper
def geocode_address(address: str):
    """
    Geocode a street address into latitude and longitude using OpenStreetMap's Nominatim.
    """
    geolocator = Nominatim(user_agent="fastapi-geocoder")
    try:
        location = geolocator.geocode(address, timeout=10)
        if location:
            return location.latitude, location.longitude
        else:
            return None, None
    except GeocoderTimedOut:
        return None, None

# Pydantic Models
class LinkInput(BaseModel):
    link: str
    description: Optional[str] = None
    address: Optional[str] = None
    lat: Optional[float] = None
    lng: Optional[float] = None

class LinkOutput(BaseModel):
    link: str
    description: Optional[str]
    location: Dict[str, float]

# Add or Update Link
@app.post("/add-or-update-link", response_model=Dict[str, str])
async def add_or_update_link(link_input: LinkInput):
    """
    Add a new link and location to the database or update the location and description of an existing link.
    """
    if link_input.lat is not None and link_input.lng is not None:
        location = {"lat": link_input.lat, "lng": link_input.lng}
    elif link_input.address:
        lat, lng = geocode_address(link_input.address)
        if lat is None or lng is None:
            raise HTTPException(status_code=400, detail="Address could not be geocoded.")
        location = {"lat": lat, "lng": lng}
    else:
        raise HTTPException(status_code=400, detail="Either address or lat/lng must be provided.")

    description = link_input.description

    existing_entry = collection.find_one({"link": link_input.link})
    if existing_entry:
        # Update the location and description of the existing link
        collection.update_one(
            {"link": link_input.link}, 
            {"$set": {"location": location, "description": description}}
        )
        return {"message": "Link updated"}
    else:
        # Insert a new link with location and description
        collection.insert_one({"link": link_input.link, "location": location, "description": description})
        return {"message": "Link added"}

# Fetch All Links
@app.get("/all-links", response_model=List[LinkOutput])
async def fetch_all_links():
    """
    Fetch all links from the database.
    """
    links = list(collection.find())
    return [
        {
            "link": item["link"], 
            "description": item.get("description", None), 
            "location": item["location"]
        }
        for item in links
    ]

# Fetch Nearby Links
@app.get("/nearby-links", response_model=List[LinkOutput])
async def fetch_nearby_links(lat: float = Query(...), lng: float = Query(...), max_distance: float = Query(1.0)):
    """
    Fetch links within a maximum distance (in kilometers).
    """
    all_links = list(collection.find())
    nearby_links = []
    for item in all_links:
        location = item["location"]
        distance = geodesic((lat, lng), (location["lat"], location["lng"])).kilometers
        if distance <= max_distance:
            nearby_links.append({
                "link": item["link"],
                "description": item.get("description", None),
                "location": location
            })
    return nearby_links

# Delete a Link
@app.delete("/delete-link", response_model=Dict[str, str])
async def delete_link(link: str):
    """
    Delete a link from the database.
    """
    result = collection.delete_one({"link": link})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Link not found")
    return {"message": "Link deleted successfully"}