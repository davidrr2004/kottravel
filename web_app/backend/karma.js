import { db, auth } from './firebase';
import { collection, query, where, orderBy, limit, onSnapshot, doc, getDoc } from "firebase/firestore";

let unsubscribeUser;
let unsubscribeLeaderboard;

// Initialize karma page
export async function initKarmaPage() {
  // Load user data if logged in
  auth.onAuthStateChanged(user => {
    if (user) {
      loadUserData(user.uid);
      setupLeaderboard();
    } else {
      // Show login prompt
      document.getElementById('loginPrompt').classList.remove('hidden');
      document.getElementById('karmaContent').classList.add('hidden');
    }
  });
}

// Load user's karma data
async function loadUserData(userId) {
  const userRef = doc(db, "users", userId);
  
  unsubscribeUser = onSnapshot(userRef, (doc) => {
    if (doc.exists()) {
      const data = doc.data();
      updateKarmaUI(data);
    } else {
      // Create user doc if doesn't exist
      setDoc(userRef, {
        karmaPoints: 0,
        totalReports: 0,
        achievements: ['first_report'],
        lastActivity: serverTimestamp()
      }, { merge: true });
    }
  });
}

function updateKarmaUI(userData) {
  // Update points display
  document.getElementById('karmaPoints').textContent = userData.karmaPoints || 0;
  
  // Update progress ring
  const circumference = 2 * Math.PI * 52;
  const progress = (userData.karmaPoints % 100) / 100; // Show progress to next 100
  const offset = circumference - (progress * circumference);
  document.querySelector('.progress-ring-circle').style.strokeDashoffset = offset;
  
  // Update achievements
  const achievements = userData.achievements || [];
  updateAchievements(achievements);
  
  // Show content
  document.getElementById('loginPrompt').classList.add('hidden');
  document.getElementById('karmaContent').classList.remove('hidden');
}

function updateAchievements(achievements) {
  const achievementMap = {
    first_report: { emoji: '🥇', title: 'First Report', desc: 'Submitted your first traffic report' },
    photo_reporter: { emoji: '📸', title: 'Photo Reporter', desc: 'Submitted 5 reports with photos' },
    quick_reporter: { emoji: '⚡', title: 'Quick Reporter', desc: 'Reported 3 issues in one day' },
    community_leader: { emoji: '👑', title: 'Community Leader', desc: 'Reach 500 karma points' }
  };
  
  const container = document.getElementById('achievementsContainer');
  container.innerHTML = '';
  
  Object.entries(achievementMap).forEach(([key, achievement]) => {
    const achieved = achievements.includes(key);
    
    const div = document.createElement('div');
    div.className = `flex items-center p-3 rounded-lg ${
      achieved ? 'bg-green-50' : 'bg-gray-50 opacity-50'
    }`;
    div.innerHTML = `
      <div class="text-2xl mr-3 ${achieved ? 'achievement-badge' : ''}">${achievement.emoji}</div>
      <div>
        <h4 class="font-medium ${achieved ? 'text-green-900' : 'text-gray-500'}">${achievement.title}</h4>
        <p class="text-sm ${achieved ? 'text-green-700' : 'text-gray-500'}">${achievement.desc}</p>
      </div>
    `;
    
    container.appendChild(div);
  });
}

// Set up leaderboard
function setupLeaderboard() {
  const leaderboardRef = collection(db, "leaderboard");
  const q = query(leaderboardRef, orderBy("karmaPoints", "desc"), limit(10));
  
  unsubscribeLeaderboard = onSnapshot(q, (snapshot) => {
    const tbody = document.querySelector('#leaderboardTable tbody');
    tbody.innerHTML = '';
    
    snapshot.forEach((doc, index) => {
      const data = doc.data();
      const tr = document.createElement('tr');
      
      tr.className = data.userId === auth.currentUser?.uid ? 'bg-green-50' : '';
      tr.innerHTML = `
        <td class="px-6 py-4 whitespace-nowrap">
          <div class="flex items-center">
            <span class="text-xl mr-2">${getRankEmoji(index)}</span>
            #${index + 1}
          </div>
        </td>
        <td class="px-6 py-4 whitespace-nowrap">
          <div class="flex items-center">
            <div class="flex-shrink-0 h-8 w-8 rounded-full bg-blue-500 flex items-center justify-center text-white font-bold">
              ${data.userName?.charAt(0) || '?'}
            </div>
            <div class="ml-4">
              <div class="text-sm font-medium">${data.userName || 'Anonymous'}</div>
              <div class="text-sm text-gray-500">${data.lastActivity?.toDate().toLocaleDateString() || ''}</div>
            </div>
          </div>
        </td>
        <td class="px-6 py-4 whitespace-nowrap font-bold">${data.karmaPoints || 0}</td>
        <td class="px-6 py-4 whitespace-nowrap">${data.totalReports || 0}</td>
        <td class="px-6 py-4 whitespace-nowrap">
          <span class="px-2 py-1 text-xs rounded-full ${
            data.accuracy >= 90 ? 'bg-green-100 text-green-800' : 
            data.accuracy >= 70 ? 'bg-yellow-100 text-yellow-800' : 'bg-red-100 text-red-800'
          }">
            ${data.accuracy || 0}%
          </span>
        </td>
      `;
      
      tbody.appendChild(tr);
    });
    
    // Add current user if not in top 10
    if (!snapshot.docs.some(doc => doc.id === auth.currentUser?.uid)) {
      addCurrentUserToLeaderboard();
    }
  });
}

function getRankEmoji(index) {
  return ['🥇', '🥈', '🥉'][index] || '🏅';
}

async function addCurrentUserToLeaderboard() {
  const userRef = doc(db, "users", auth.currentUser.uid);
  const userDoc = await getDoc(userRef);
  
  if (userDoc.exists()) {
    const data = userDoc.data();
    const tbody = document.querySelector('#leaderboardTable tbody');
    
    const tr = document.createElement('tr');
    tr.className = 'bg-green-50';
    tr.innerHTML = `
      <td class="px-6 py-4 whitespace-nowrap">#-</td>
      <td class="px-6 py-4 whitespace-nowrap">
        <div class="flex items-center">
          <div class="flex-shrink-0 h-8 w-8 rounded-full bg-green-500 flex items-center justify-center text-white font-bold">
            ${auth.currentUser.displayName?.charAt(0) || 'Y'}
          </div>
          <div class="ml-4">
            <div class="text-sm font-medium">You</div>
            <div class="text-sm text-gray-500">Today</div>
          </div>
        </div>
      </td>
      <td class="px-6 py-4 whitespace-nowrap font-bold">${data.karmaPoints || 0}</td>
      <td class="px-6 py-4 whitespace-nowrap">${data.totalReports || 0}</td>
      <td class="px-6 py-4 whitespace-nowrap">
        <span class="px-2 py-1 text-xs rounded-full ${
          data.accuracy >= 90 ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'
        }">
          ${data.accuracy || '100'}%
        </span>
      </td>
    `;
    
    tbody.appendChild(tr);
  }
}

// Clean up listeners
window.addEventListener('beforeunload', () => {
  if (unsubscribeUser) unsubscribeUser();
  if (unsubscribeLeaderboard) unsubscribeLeaderboard();
});