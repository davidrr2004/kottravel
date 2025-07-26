import { db, auth } from './firebase';
import { collection, query, where, onSnapshot } from "firebase/firestore";

let map;
let trafficMarkers = [];
let unsubscribeTraffic;

// Initialize map with traffic data
export async function initLiveMap() {
  // Initialize your map (Leaflet/Google Maps)
  map = L.map('trafficMap').setView([10.9942, 76.0062], 13);
  
  // Add base map tiles
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '© OpenStreetMap contributors'
  }).addTo(map);

  // Set up traffic data listener
  setupTrafficUpdates();
  
  // Set up auth state listener
  auth.onAuthStateChanged(user => {
    if (user) {
      if (!unsubscribeTraffic) {
        setupTrafficUpdates();
      }
    } else {
      if (unsubscribeTraffic) {
        unsubscribeTraffic();
        unsubscribeTraffic = null;
      }
    }
  });
}

function setupTrafficUpdates() {
  // Clear existing markers
  trafficMarkers.forEach(marker => map.removeLayer(marker));
  trafficMarkers = [];
  
  // Query for recent traffic data (last 2 hours)
  const q = query(collection(db, "trafficData"), 
    where("timestamp", ">", new Date(Date.now() - 7200000)));
  
  unsubscribeTraffic = onSnapshot(q, (snapshot) => {
    snapshot.docChanges().forEach((change) => {
      const data = change.doc.data();
      const markerId = `marker-${change.doc.id}`;
      
      if (change.type === "added") {
        // Add new marker
        const marker = L.marker([data.coordinates.latitude, data.coordinates.longitude], {
          icon: getTrafficIcon(data.congestionLevel)
        }).addTo(map);
        
        marker.bindPopup(`
          <div class="p-2">
            <h3 class="font-bold">${data.type || 'Traffic Incident'}</h3>
            <p>${data.description || 'No description'}</p>
            <p class="text-sm text-gray-600 mt-1">
              Reported: ${new Date(data.timestamp?.toDate()).toLocaleTimeString()}
            </p>
          </div>
        `);
        
        marker.markerId = markerId;
        trafficMarkers.push(marker);
      }
      
      if (change.type === "modified") {
        // Update existing marker
        const marker = trafficMarkers.find(m => m.markerId === markerId);
        if (marker) {
          marker.setIcon(getTrafficIcon(data.congestionLevel));
          marker.setPopupContent(`
            <div class="p-2">
              <h3 class="font-bold">${data.type || 'Traffic Incident'}</h3>
              <p>${data.description || 'No description'}</p>
              <p class="text-sm text-gray-600 mt-1">
                Updated: ${new Date(data.timestamp?.toDate()).toLocaleTimeString()}
              </p>
            </div>
          `);
        }
      }
      
      if (change.type === "removed") {
        // Remove marker
        const markerIndex = trafficMarkers.findIndex(m => m.markerId === markerId);
        if (markerIndex !== -1) {
          map.removeLayer(trafficMarkers[markerIndex]);
          trafficMarkers.splice(markerIndex, 1);
        }
      }
    });
  });
}

function getTrafficIcon(congestionLevel) {
  const color = 
    congestionLevel > 70 ? 'red' :
    congestionLevel > 40 ? 'orange' : 'green';
  
  return L.divIcon({
    html: `
      <div class="relative">
        <svg width="24" height="24" viewBox="0 0 24 24">
          <circle cx="12" cy="12" r="10" fill="${color}" opacity="0.8"/>
          <text x="12" y="16" text-anchor="middle" fill="white" font-size="12">
            ${congestionLevel}%
          </text>
        </svg>
      </div>
    `,
    className: '',
    iconSize: [24, 24],
    iconAnchor: [12, 12]
  });
}

// Clean up when leaving page
window.addEventListener('beforeunload', () => {
  if (unsubscribeTraffic) {
    unsubscribeTraffic();
  }
});