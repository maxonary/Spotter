import streamlit as st
from folium import Map, Marker
from streamlit_folium import st_folium
from geopy.geocoders import Nominatim
from geopy.exc import GeocoderTimedOut


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


def main():
    st.title("Link Location Mapper with Address Input")

    st.write("""
    Enter a link (e.g., a website, YouTube video, or image URL) and place it on the map.
    You can either:
    - Enter a street address to locate it automatically.
    - Click on the map to set its location.
    - Manually enter latitude and longitude values.
    """)

    # Input field for the link
    link = st.text_input("Enter a link (URL)", placeholder="https://example.com")
    if not link:
        st.warning("Please enter a link to proceed.")
        return

    # Map location initialization
    if "map_location" not in st.session_state:
        st.session_state.map_location = None

    # Input field for a street address
    st.subheader("Enter a Street Address")
    address = st.text_input("Street Address (e.g., '1600 Amphitheatre Parkway, Mountain View, CA')")
    if st.button("Geocode Address"):
        if address.strip():
            lat, lon = geocode_address(address)
            if lat is not None and lon is not None:
                st.session_state.map_location = {"lat": lat, "lng": lon}
                st.success(f"Address found: Latitude={lat}, Longitude={lon}")
            else:
                st.error("Could not find the address. Please try a different one.")

    # Map display
    st.subheader("Select Location on the Map")
    map_center = [0, 0]  # Default to [0, 0] if no location is set
    map_zoom = 2  # Default zoom level
    if st.session_state.map_location:
        map_center = [
            st.session_state.map_location.get("lat", 0),
            st.session_state.map_location.get("lng", 0),
        ]
        map_zoom = 8  # Zoom in when a location is set

    # Create the map
    link_map = Map(location=map_center, zoom_start=map_zoom)
    if st.session_state.map_location:
        # Add a marker for the current location
        Marker(
            [st.session_state.map_location["lat"], st.session_state.map_location["lng"]],
            tooltip=f"Link: {link}",
        ).add_to(link_map)

    # Interactive map for selecting a location
    map_data = st_folium(link_map, width=700, height=500)

    # Capture the last clicked location
    if map_data and map_data.get("last_clicked"):
        st.session_state.map_location = map_data["last_clicked"]
        st.success(
            f"Location selected: Latitude={st.session_state.map_location['lat']}, "
            f"Longitude={st.session_state.map_location['lng']}"
        )

    # Option to manually enter latitude and longitude
    st.subheader("Manually Enter Location")
    latitude = st.number_input(
        "Latitude", value=st.session_state.map_location["lat"] if st.session_state.map_location else 0.0, step=0.0001
    )
    longitude = st.number_input(
        "Longitude", value=st.session_state.map_location["lng"] if st.session_state.map_location else 0.0, step=0.0001
    )

    if st.button("Save Location"):
        st.session_state.map_location = {"lat": latitude, "lng": longitude}
        st.success(f"Location saved: Latitude={latitude}, Longitude={longitude}")

    # Display saved link and location
    if st.session_state.map_location:
        st.subheader("Saved Link and Location")
        st.write(f"**Link:** {link}")
        st.write(
            f"**Location:** Latitude={st.session_state.map_location['lat']}, "
            f"Longitude={st.session_state.map_location['lng']}"
        )


if __name__ == "__main__":
    main()