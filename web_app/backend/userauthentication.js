import { auth } from './firebase';
import { 
  signInWithEmailAndPassword,
  signInWithPopup,
  GoogleAuthProvider,
  signOut,
  onAuthStateChanged
} from "firebase/auth";

const provider = new GoogleAuthProvider();

// Initialize auth UI
export function initAuth() {
  const userInfo = document.getElementById('userInfo');
  const loginButtons = document.getElementById('loginButtons');
  const userAvatar = document.getElementById('userAvatar');
  const userName = document.getElementById('userName');
  const userKarma = document.getElementById('userKarma');
  const logoutBtn = document.getElementById('logoutBtn');
  const googleLoginBtn = document.getElementById('googleLoginBtn');

  // Auth state observer
  onAuthStateChanged(auth, (user) => {
    if (user) {
      // User is signed in
      userInfo.classList.remove('hidden');
      loginButtons.classList.add('hidden');
      
      // Update user info
      userName.textContent = user.displayName || user.email;
      userKarma.textContent = '0 pts'; // Will be updated from Firestore
      userAvatar.src = user.photoURL || 'https://via.placeholder.com/40';
      
      // Load user data from Firestore
      loadUserData(user.uid);
    } else {
      // User is signed out
      userInfo.classList.add('hidden');
      loginButtons.classList.remove('hidden');
    }
  });

  // Event listeners
  if (googleLoginBtn) {
    googleLoginBtn.addEventListener('click', googleLogin);
  }
  
  if (logoutBtn) {
    logoutBtn.addEventListener('click', logout);
  }
}

// Google login
async function googleLogin() {
  try {
    await signInWithPopup(auth, provider);
  } catch (error) {
    console.error("Google login error:", error);
    alert(`Login failed: ${error.message}`);
  }
}

// Email/password login
export async function login(email, password) {
  try {
    await signInWithEmailAndPassword(auth, email, password);
  } catch (error) {
    console.error("Login error:", error);
    throw error;
  }
}

// Logout
async function logout() {
  try {
    await signOut(auth);
  } catch (error) {
    console.error("Logout error:", error);
    alert(`Logout failed: ${error.message}`);
  }
}

// Load additional user data from Firestore
async function loadUserData(userId) {
  const userKarma = document.getElementById('userKarma');
  if (!userKarma) return;
  
  try {
    const userDoc = await getDoc(doc(db, "users", userId));
    if (userDoc.exists()) {
      const data = userDoc.data();
      userKarma.textContent = `${data.karmaPoints || 0} pts`;
    }
  } catch (error) {
    console.error("Error loading user data:", error);
  }
}