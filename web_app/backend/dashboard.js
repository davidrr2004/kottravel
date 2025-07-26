import { db } from './firebase';
import { collection, query, where, orderBy, limit, onSnapshot } from "firebase/firestore";

let hourlyChart;
let reportTypesChart;
let unsubscribeReports;

// Initialize dashboard
export async function initDashboard() {
  initCharts();
  setupRealTimeUpdates();
}

function initCharts() {
  const hourlyCtx = document.getElementById('hourlyChart').getContext('2d');
  hourlyChart = new Chart(hourlyCtx, {
    type: 'line',
    data: { labels: [], datasets: [] },
    options: chartOptions('Congestion Level (%)')
  });

  const reportTypesCtx = document.getElementById('reportTypesChart').getContext('2d');
  reportTypesChart = new Chart(reportTypesCtx, {
    type: 'doughnut',
    data: { labels: [], datasets: [] },
    options: {
      responsive: true,
      plugins: {
        legend: { position: 'bottom' }
      }
    }
  });
}

function setupRealTimeUpdates() {
  // Hourly congestion data
  const hourlyQuery = query(
    collection(db, "trafficStats"), 
    where("timestamp", ">", new Date(Date.now() - 86400000)), // Last 24 hours
    orderBy("timestamp")
  );
  
  unsubscribeReports = onSnapshot(hourlyQuery, (snapshot) => {
    const hourlyData = Array(24).fill(0);
    const hourlyCount = Array(24).fill(0);
    
    snapshot.forEach(doc => {
      const data = doc.data();
      const hour = new Date(data.timestamp.toDate()).getHours();
      hourlyData[hour] += data.congestionLevel;
      hourlyCount[hour]++;
    });
    
    // Calculate averages
    const hourlyAverages = hourlyData.map((sum, i) => 
      hourlyCount[i] ? Math.round(sum / hourlyCount[i]) : 0
    );
    
    // Update chart
    hourlyChart.data.labels = Array.from({length: 24}, (_, i) => `${i}:00`);
    hourlyChart.data.datasets = [{
      label: 'Congestion Level',
      data: hourlyAverages,
      backgroundColor: 'rgba(60, 179, 113, 0.1)',
      borderColor: '#3CB371',
      borderWidth: 3,
      tension: 0.4
    }];
    hourlyChart.update();
  });
  
  // Report types data
  const reportsQuery = query(
    collection(db, "reports"),
    where("timestamp", ">", new Date(Date.now() - 604800000)) // Last 7 days
  );
  
  onSnapshot(reportsQuery, (snapshot) => {
    const typeCounts = {
      Accident: 0,
      Pothole: 0,
      Roadblock: 0,
      Flooding: 0,
      Other: 0
    };
    
    snapshot.forEach(doc => {
      const type = doc.data().type || 'Other';
      typeCounts[type] = (typeCounts[type] || 0) + 1;
    });
    
    // Update chart
    reportTypesChart.data.labels = Object.keys(typeCounts);
    reportTypesChart.data.datasets = [{
      data: Object.values(typeCounts),
      backgroundColor: [
        '#EF4444', // Accident - red
        '#F59E0B', // Pothole - orange
        '#3B82F6', // Roadblock - blue
        '#10B981', // Flooding - green
        '#6B7280'  // Other - gray
      ]
    }];
    reportTypesChart.update();
  });
}

function chartOptions(title) {
  return {
    responsive: true,
    plugins: {
      title: { display: true, text: title },
      legend: { display: false }
    },
    scales: {
      y: { beginAtZero: true, max: 100 },
      x: { grid: { display: false } }
    }
  };
}

// Clean up
window.addEventListener('beforeunload', () => {
  if (unsubscribeReports) unsubscribeReports();
});