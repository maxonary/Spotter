import streamlit as st
from folium import Map, Marker
from folium.plugins import MarkerCluster
from streamlit_folium import st_folium
from geopy.geocoders import Nominatim
from geopy.exc import GeocoderTimedOut
import validators
from pymongo import MongoClient

# MongoDB configuration from .env
MONGO_URI = st.secrets["MONGO_URI"]
DB_NAME = "LinkLocationDB"  # Default database name
COLLECTION_NAME = "links"   # Default collection name

# Default map center (Berlin) from Streamlit secrets
DEFAULT_MAP_CENTER = st.secrets["DEFAULT_MAP_CENTER"]

def get_db():
    """Connect to the MongoDB and return the collection."""
    client = MongoClient(MONGO_URI)
    db = client[DB_NAME]
    return db[COLLECTION_NAME]


def geocode_address(address):
    """
    Geocode a street address into latitude and longitude using OpenStreetMap's Nominatim.
    """
    geolocator = Nominatim(user_agent="streamlit-geocoder")
    try:
        location = geolocator.geocode(address, timeout=10)
        if location:
            return location.latitude, location.longitude
        else:
            return None, None
    except GeocoderTimedOut:
        st.error("Geocoding request timed out. Please try again.")
        return None, None


def is_valid_url(url):
    """
    Validate the provided URL.
    """
    return validators.url(url)


def add_or_update_link(collection, link, location, description):
    """
    Add a new link, location, and description to the database or update the location and description of an existing link.
    """
    existing_entry = collection.find_one({"link": link})
    if existing_entry:
        # Update the location and description of the existing link
        collection.update_one(
            {"link": link}, 
            {"$set": {"location": location, "description": description}}
        )
        return "updated"
    else:
        # Insert a new link with location and description
        collection.insert_one({"link": link, "location": location, "description": description})
        return "added"


def fetch_all_links(collection):
    """Fetch all links from the database."""
    return list(collection.find())


def main():
    st.title("Interactive Link Location Mapper with MongoDB")

    st.write("""
    Add links, locate them on a map, and see all previously added links.
    - Enter a valid URL and avoid duplicates.
    - Enter a street address to locate the link automatically.
    - Click on the map to set its location.
    - Manually enter latitude and longitude values.
    """)

    # Connect to MongoDB
    collection = get_db()

    # Input for new link
    st.subheader("Add or Update a Link")
    link = st.text_input("Enter a link (URL)", placeholder="https://example.com")

    if link and not is_valid_url(link):
        st.error("Please enter a valid URL.")
        return

    # Input for description
    description = st.text_input("Enter a description for the link", placeholder="Brief description of the link")

    # Input for street address
    st.subheader("Enter a Street Address")
    address = st.text_input("Street Address (e.g., '1600 Amphitheatre Parkway, Mountain View, CA')")

    if st.button("Save or Update Location"):
        if address.strip() and link.strip() and description.strip():
            # Geocode the address
            lat, lon = geocode_address(address)
            if lat is not None and lon is not None:
                st.session_state.map_location = {"lat": lat, "lng": lon}
                location = st.session_state.map_location
                # Save or update the link with the geocoded location and description
                action = add_or_update_link(collection, link, location, description)
                if action == "updated":
                    st.success(f"Link updated: {link} now at Latitude={location['lat']}, Longitude={location['lng']}")
                else:
                    st.success(f"Link saved: {link} at Latitude={location['lat']}, Longitude={location['lng']}")
            else:
                st.error("Could not find the address. Please try a different one.")
        else:
            st.error("Please enter an address, a valid link, and a description.")

    # Display all links on the map
    st.subheader("Interactive Map of Links")
    map_center = [DEFAULT_MAP_CENTER["lat"], DEFAULT_MAP_CENTER["lng"]]
    map_zoom = 12  # Set a reasonable default zoom level for Berlin

    # Fetch all links from the database
    all_links = fetch_all_links(collection)

    # Create a Folium map
    link_map = Map(location=map_center, zoom_start=map_zoom)
    marker_cluster = MarkerCluster().add_to(link_map)

    for item in all_links:
        link = item["link"]
        location = item["location"]
        description = item.get("description", "No description provided")
        Marker(
            [location["lat"], location["lng"]],
            popup=f'<b>{description}</b><br><a href="{link}" target="_blank">{link}</a>',
            tooltip=link,
        ).add_to(marker_cluster)

    # Render the map
    st_folium(link_map, width=700, height=500)


if __name__ == "__main__":
    main()