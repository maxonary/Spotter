import streamlit as st
import tempfile
import subprocess
from pathlib import Path
import json
from geopy.geocoders import Nominatim
from folium import Map, Marker
from streamlit_folium import st_folium
import re


def dms_to_decimal(dms_str):
    """
    Converts a DMS (Degrees, Minutes, Seconds) string to decimal degrees.
    Example: '52 deg 28\' 46.56" N' -> 52.4796
    """
    dms_regex = re.match(r"(\d+) deg (\d+)' (\d+\.\d+)\" ([NSEW])", dms_str)
    if not dms_regex:
        return None

    degrees, minutes, seconds, direction = dms_regex.groups()
    decimal = float(degrees) + float(minutes) / 60 + float(seconds) / 3600

    # Negative for South and West directions
    if direction in ("S", "W"):
        decimal = -decimal

    return decimal


def read_metadata(video_path):
    """
    Reads metadata from the video using ExifTool.
    Returns a dictionary of metadata.
    """
    try:
        command = ["exiftool", "-json", video_path]
        result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
        metadata = json.loads(result.stdout)
        return metadata[0]  # Return metadata for the file
    except subprocess.CalledProcessError as e:
        st.error(f"Error reading metadata: {e}")
        return None


def extract_geolocation(metadata):
    """
    Extracts geolocation data from metadata if available and converts to decimal degrees.
    """
    latitude_str = metadata.get("GPSLatitude")
    longitude_str = metadata.get("GPSLongitude")

    # Convert DMS to decimal degrees if needed
    latitude = dms_to_decimal(latitude_str) if latitude_str else None
    longitude = dms_to_decimal(longitude_str) if longitude_str else None

    return latitude, longitude

def generate_thumbnail(video_path, output_path):
    """
    Generates a thumbnail image from the video using ffmpeg.
    """
    try:
        command = [
            "ffmpeg",
            "-i", video_path,
            "-ss", "00:00:01.000",  # Capture at 1 second
            "-vframes", "1",        # Capture one frame
            output_path,
        ]
        subprocess.run(command, check=True)
        return output_path
    except subprocess.CalledProcessError as e:
        st.error(f"Error generating thumbnail: {e}")
        return None

def modify_video_metadata(video_path, latitude, longitude):
    """
    Modifies the geolocation metadata of a video file.
    Requires ExifTool to be installed.
    """
    try:
        command = [
            "exiftool",
            f"-GPSLatitude={latitude}",
            f"-GPSLongitude={longitude}",
            f"-GPSLatitudeRef={'N' if latitude >= 0 else 'S'}",
            f"-GPSLongitudeRef={'E' if longitude >= 0 else 'W'}",
            "-overwrite_original",
            video_path,
        ]
        subprocess.run(command, check=True)
        return True
    except subprocess.CalledProcessError as e:
        st.error(f"Error modifying metadata: {e}")
        return False


# Streamlit App UI
def main():
    st.title("Map-Based Video Location Viewer & Editor")

    st.write("""
    Upload videos to display their locations on a map.
    If a video lacks geolocation data, you can assign a location manually.
    """)

    # Initialize session state for marker placement
    if "map_location" not in st.session_state:
        st.session_state.map_location = None

    # File uploader
    video_file = st.file_uploader("Upload a video file", type=["mp4", "mov", "avi", "mkv"])

    if video_file:
        # Save the uploaded video temporarily
        with tempfile.NamedTemporaryFile(delete=False, suffix=".mp4") as temp_video:
            temp_video.write(video_file.read())
            temp_video_path = temp_video.name

        st.success(f"Video uploaded: {video_file.name}")

        # Read metadata
        st.subheader("Video Metadata")
        metadata = read_metadata(temp_video_path)
        latitude, longitude = None, None
        if metadata:
            latitude, longitude = extract_geolocation(metadata)
            if latitude is not None and longitude is not None:
                st.write(f"**Latitude:** {latitude}")
                st.write(f"**Longitude:** {longitude}")
            else:
                st.warning("No geolocation data found in the metadata.")

        # Map display
        st.subheader("Video Location on Map")
        map_center = [latitude, longitude] if latitude and longitude else [0, 0]
        video_map = Map(location=map_center, zoom_start=4)

        if latitude and longitude:
            # Add existing location marker
            Marker([latitude, longitude], tooltip="Current Location").add_to(video_map)

        # Add interactivity for assigning location
        st.write("Click on the map to assign a new location for the video.")
        map_data = st_folium(video_map, width=700, height=500)

        # Get new location from user interaction
        if map_data and map_data.get("last_clicked"):
            st.session_state.map_location = map_data["last_clicked"]

        if st.session_state.map_location:
            new_lat, new_lon = st.session_state.map_location["lat"], st.session_state.map_location["lng"]
            st.success(f"New location selected: Latitude={new_lat}, Longitude={new_lon}")

            # Modify metadata if the user confirms
            if st.button("Save Location to Video"):
                with st.spinner("Saving location..."):
                    success = modify_video_metadata(temp_video_path, new_lat, new_lon)
                    if success:
                        st.success("Location saved successfully!")
                    else:
                        st.error("Failed to save the location.")

        # Download modified video
        st.subheader("Download Modified Video")
        if Path(temp_video_path).exists():
            with open(temp_video_path, "rb") as video:
                st.download_button(
                    label="Download Video",
                    data=video,
                    file_name=f"modified_{video_file.name}",
                    mime="video/mp4",
                )


# Run the Streamlit app
if __name__ == "__main__":
    main()