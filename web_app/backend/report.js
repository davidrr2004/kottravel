import { db, storage, auth } from './firebase';
import { collection, addDoc, serverTimestamp } from "firebase/firestore";
import { ref, uploadBytes, getDownloadURL } from "firebase/storage";
import { doc, updateDoc, increment } from "firebase/firestore";

// Initialize report form
export function initReportForm() {
  const form = document.getElementById('reportForm');
  const photoUpload = document.getElementById('photoUpload');
  const photoPreview = document.getElementById('photoPreview');
  const previewImage = document.getElementById('previewImage');

  // Photo upload preview
  photoUpload.addEventListener('change', (e) => {
    const file = e.target.files[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = (e) => {
        previewImage.src = e.target.result;
        photoPreview.classList.remove('hidden');
      };
      reader.readAsDataURL(file);
    }
  });

  // Form submission
  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const submitBtn = document.getElementById('submitReport');
    submitBtn.disabled = true;
    submitBtn.innerHTML = '<i data-feather="loader" class="animate-spin w-4 h-4 mr-2"></i> Submitting...';
    feather.replace();

    try {
      const reportId = await submitReport({
        type: selectedIssueType,
        description: document.getElementById('issueDescription').value,
        location: document.getElementById('addressText').textContent,
        coordinates: pinnedLocation,
        photoFile: photoUpload.files[0] || null
      });

      // Show success message
      showAlert('success', 'Report submitted successfully!');
      
      // Reset form
      form.reset();
      photoPreview.classList.add('hidden');
      
      // Award karma points if logged in
      if (auth.currentUser) {
        await awardKarmaPoints(auth.currentUser.uid, 10);
      }
    } catch (error) {
      console.error("Submission error:", error);
      showAlert('error', `Failed to submit report: ${error.message}`);
    } finally {
      submitBtn.disabled = false;
      submitBtn.textContent = 'Submit Report';
    }
  });
}

// Submit report to Firebase
async function submitReport(reportData) {
  let photoURL = null;
  
  // Upload photo if exists
  if (reportData.photoFile) {
    const storageRef = ref(storage, `reports/${Date.now()}_${reportData.photoFile.name}`);
    await uploadBytes(storageRef, reportData.photoFile);
    photoURL = await getDownloadURL(storageRef);
  }

  // Add report to Firestore
  const docRef = await addDoc(collection(db, "reports"), {
    type: reportData.type,
    description: reportData.description,
    location: reportData.location,
    coordinates: new firebase.firestore.GeoPoint(
      reportData.coordinates.lat,
      reportData.coordinates.lng
    ),
    photoURL: photoURL,
    timestamp: serverTimestamp(),
    status: "pending",
    userId: auth.currentUser?.uid || null,
    userName: auth.currentUser?.displayName || "Anonymous",
    karmaAwarded: false,
    upvotes: 0,
    downvotes: 0
  });

  return docRef.id;
}

// Award karma points
async function awardKarmaPoints(userId, points) {
  const userRef = doc(db, "users", userId);
  
  try {
    await updateDoc(userRef, {
      karmaPoints: increment(points),
      totalReports: increment(1),
      lastActivity: serverTimestamp()
    }, { merge: true });
    
    // Update UI if on karma page
    const karmaDisplay = document.getElementById('karmaPoints');
    if (karmaDisplay) {
      const current = parseInt(karmaDisplay.textContent) || 0;
      karmaDisplay.textContent = current + points;
    }
  } catch (error) {
    console.error("Error awarding karma:", error);
  }
}

// Helper function to show alerts
function showAlert(type, message) {
  const alertDiv = document.createElement('div');
  alertDiv.className = `fixed top-4 right-4 p-4 rounded-lg shadow-lg ${
    type === 'success' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
  }`;
  alertDiv.innerHTML = `
    <div class="flex items-center">
      <i data-feather="${type === 'success' ? 'check-circle' : 'alert-circle'}" class="w-5 h-5 mr-2"></i>
      <span>${message}</span>
    </div>
  `;
  document.body.appendChild(alertDiv);
  feather.replace();
  
  setTimeout(() => {
    alertDiv.remove();
  }, 5000);
}