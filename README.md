# Meme Map Application

## Overview
The Meme Map application is an interactive platform for geolocating and displaying links (e.g., memes, resources) on a map. It integrates a FastAPI backend and a Streamlit frontend for a seamless user experience. The application also supports MongoDB for database storage.

---

## Features
1. **FastAPI Backend**:
   - Provides RESTful API endpoints for managing and querying geolocated links.
   - Auto-generated Swagger documentation available at `/docs`.

2. **Streamlit Frontend**:
   - Interactive web interface for adding, updating, and visualizing links on a map.
   - Communicates with the FastAPI backend.

3. **MongoDB Integration**:
   - Stores link information, geolocation data, and optional descriptions.
   - Allows querying and filtering of stored links.

4. **Geocoding Support**:
   - Converts street addresses to latitude and longitude coordinates using OpenStreetMap's Nominatim API.

5. **Interactive Map**:
   - Displays stored links with markers.
   - Allows users to explore links based on location.

---

## Installation

### Prerequisites
- Python 3.10 or higher.
- MongoDB instance (local or cloud-based).
- Node.js and npm (optional, for advanced development).

### Setup
1. **Clone the Repository:**
   ```bash
   git clone https://github.com/yourusername/meme-map.git
   cd meme-map
   ```

2. **Set Up the Environment:**
   - Create a virtual environment:
     ```bash
     python -m venv venv
     source venv/bin/activate  # On Windows: venv\Scripts\activate
     ```
   - Install dependencies:
     ```bash
     pip install -r requirements.txt
     ```

3. **Configure Secrets:**
   - Create a `.env` file in the root directory with the following content:
     ```env
     MONGO_URI=<your_mongo_connection_string>
     ```
   - For Streamlit, configure `secrets.toml` in the `.streamlit` folder:
     ```toml
     [default]
     MONGO_URI = "<your_mongo_connection_string>"
     ```

4. **Run the Application:**
   - Start the FastAPI server:
     ```bash
     uvicorn api_meme_map:app --host 0.0.0.0 --port 8000
     ```
   - Start the Streamlit frontend:
     ```bash
     streamlit run meme_map.py
     ```

---

## Deployment

### Hosting FastAPI
- Use platforms like **Render**, **Railway**, or **Heroku** for hosting the FastAPI backend.
- Example `Procfile` for Heroku:
  ```
  web: uvicorn api_meme_map:app --host 0.0.0.0 --port $PORT
  ```

### Hosting Streamlit
- Use **Streamlit Cloud** for deploying the frontend.
- Push your code to GitHub and link the repository to Streamlit Cloud.

---

## Usage

### FastAPI Endpoints
- **Swagger Documentation**: Navigate to `/docs` for auto-generated API documentation.
- **Key Endpoints**:
  - `POST /add-or-update-link`: Add or update a link.
  - `GET /all-links`: Fetch all stored links.
  - `GET /nearby-links`: Fetch links within a specific radius.
  - `DELETE /delete-link`: Delete a link by URL.

### Streamlit Features
1. Add a link with geolocation:
   - Enter a valid URL, address, or coordinates.
   - Provide an optional description.
2. View and interact with links on the map:
   - Click markers to view link details.
   - Filter links by location and distance.

---

## Project Structure
```
.
├── api_meme_map.py         # FastAPI backend
├── meme_map.py             # Streamlit frontend
├── requirements.txt        # Python dependencies
├── .streamlit/
│   └── secrets.toml        # Streamlit secrets configuration
├── .env                    # Environment variables for FastAPI
├── README.md               # Project documentation
```

---

## Contributing
1. Fork the repository.
2. Create a feature branch:
   ```bash
   git checkout -b feature-name
   ```
3. Commit your changes:
   ```bash
   git commit -m "Add feature description"
   ```
4. Push to the branch:
   ```bash
   git push origin feature-name
   ```
5. Open a pull request.

---

## License
This project is licensed under the [Apache 2.0 License](LICENSE).

---

## Acknowledgments
- [Streamlit](https://streamlit.io/)
- [FastAPI](https://fastapi.tiangolo.com/)
- [MongoDB](https://www.mongodb.com/)
- [Nominatim API](https://nominatim.openstreetmap.org/)

