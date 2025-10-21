// PDF.js worker configuration
pdfjsLib.GlobalWorkerOptions.workerSrc = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js';

let pdfDoc = null;
let currentPage = 1;
let pageRendering = false;
let pageNumPending = null;
let scale = 1.5;
let canvas = document.getElementById('pdf-canvas');
let ctx = canvas.getContext('2d');

// Load PDF document
function loadPDF() {
  const loadingTask = pdfjsLib.getDocument({
    url: '/sphragis/documents/view?path=' + encodeURIComponent(pdfPath)
  });

  loadingTask.promise.then(function(pdf) {
    pdfDoc = pdf;
    document.getElementById('total-pages').textContent = pdf.numPages;

    // Initial page render
    const selectedPage = parseInt(document.getElementById('page-select').value) || 1;
    currentPage = selectedPage;
    document.getElementById('current-page').textContent = currentPage;
    renderPage(currentPage);
  }).catch(function(error) {
    console.error('Error loading PDF:', error);
    showStatus('Error loading PDF: ' + error.message, 'error');
  });
}

// Render a page
function renderPage(num) {
  pageRendering = true;

  pdfDoc.getPage(num).then(function(page) {
    const viewport = page.getViewport({ scale: scale });
    canvas.height = viewport.height;
    canvas.width = viewport.width;

    const renderContext = {
      canvasContext: ctx,
      viewport: viewport
    };

    const renderTask = page.render(renderContext);

    renderTask.promise.then(function() {
      pageRendering = false;
      if (pageNumPending !== null) {
        renderPage(pageNumPending);
        pageNumPending = null;
      }

      // Update signature box position after render
      updateSignatureBox();
    });
  });

  document.getElementById('current-page').textContent = num;
}

// Queue page rendering
function queueRenderPage(num) {
  if (pageRendering) {
    pageNumPending = num;
  } else {
    renderPage(num);
  }
}

// Previous page
document.getElementById('prev-page').addEventListener('click', function() {
  if (currentPage <= 1) {
    return;
  }
  currentPage--;
  queueRenderPage(currentPage);
});

// Next page
document.getElementById('next-page').addEventListener('click', function() {
  if (currentPage >= pdfDoc.numPages) {
    return;
  }
  currentPage++;
  queueRenderPage(currentPage);
});

// Update signature box position and size
function updateSignatureBox() {
  const signatureBox = document.getElementById('signature-box');
  const viewer = document.getElementById('pdf-viewer');
  const canvasRect = canvas.getBoundingClientRect();
  const viewerRect = viewer.getBoundingClientRect();

  const x = parseInt(document.getElementById('x-position').value);
  const y = parseInt(document.getElementById('y-position').value);
  const width = parseInt(document.getElementById('width').value);
  const height = parseInt(document.getElementById('height').value);

  // Calculate position relative to canvas
  // PDF coordinates are from bottom-left, canvas is from top-left
  const pdfHeight = canvas.height / scale;
  const actualY = pdfHeight - y - height;

  const left = canvasRect.left - viewerRect.left + (x * scale) + viewer.scrollLeft;
  const top = canvasRect.top - viewerRect.top + (actualY * scale) + viewer.scrollTop;

  signatureBox.style.left = left + 'px';
  signatureBox.style.top = top + 'px';
  signatureBox.style.width = (width * scale) + 'px';
  signatureBox.style.height = (height * scale) + 'px';

  // Only show on current page
  const selectedPage = parseInt(document.getElementById('page-select').value);
  if (selectedPage === currentPage) {
    signatureBox.style.display = 'block';
  } else {
    signatureBox.style.display = 'none';
  }
}

// Make signature box draggable
let isDragging = false;
let dragStartX, dragStartY;
const signatureBox = document.getElementById('signature-box');

signatureBox.addEventListener('mousedown', function(e) {
  isDragging = true;
  dragStartX = e.clientX - signatureBox.offsetLeft;
  dragStartY = e.clientY - signatureBox.offsetTop;
  signatureBox.style.cursor = 'grabbing';
});

document.addEventListener('mousemove', function(e) {
  if (isDragging) {
    const viewer = document.getElementById('pdf-viewer');
    const canvasRect = canvas.getBoundingClientRect();
    const viewerRect = viewer.getBoundingClientRect();

    let newLeft = e.clientX - dragStartX;
    let newTop = e.clientY - dragStartY;

    // Update position
    signatureBox.style.left = newLeft + 'px';
    signatureBox.style.top = newTop + 'px';

    // Calculate PDF coordinates
    const canvasLeft = canvasRect.left - viewerRect.left + viewer.scrollLeft;
    const canvasTop = canvasRect.top - viewerRect.top + viewer.scrollTop;

    const relativeLeft = newLeft - canvasLeft;
    const relativeTop = newTop - canvasTop;

    const pdfX = Math.round(relativeLeft / scale);
    const pdfHeight = canvas.height / scale;
    const boxHeight = parseInt(document.getElementById('height').value);
    const pdfY = Math.round(pdfHeight - (relativeTop / scale) - boxHeight);

    // Update form fields
    document.getElementById('x-position').value = Math.max(0, pdfX);
    document.getElementById('y-position').value = Math.max(0, pdfY);
  }
});

document.addEventListener('mouseup', function() {
  if (isDragging) {
    isDragging = false;
    signatureBox.style.cursor = 'move';
  }
});

// Update preview button
document.getElementById('update-preview-btn').addEventListener('click', function() {
  const selectedPage = parseInt(document.getElementById('page-select').value);
  if (selectedPage !== currentPage) {
    currentPage = selectedPage;
    queueRenderPage(currentPage);
  } else {
    updateSignatureBox();
  }
  showStatus('Preview updated', 'success');
});

// Page select change
document.getElementById('page-select').addEventListener('change', function() {
  const selectedPage = parseInt(this.value);
  currentPage = selectedPage;
  queueRenderPage(currentPage);
});

// Form inputs change - update signature box
['x-position', 'y-position', 'width', 'height'].forEach(function(id) {
  document.getElementById(id).addEventListener('input', function() {
    updateSignatureBox();
  });
});

// Sign document
document.getElementById('signature-form').addEventListener('submit', function(e) {
  e.preventDefault();

  const formData = new FormData(this);
  formData.append('path', pdfPath);

  const data = {};
  formData.forEach((value, key) => {
    data[key] = value;
  });

  showStatus('Signing document...', 'info');
  document.getElementById('sign-btn').disabled = true;

  fetch('/sphragis/documents/sign', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content
    },
    body: JSON.stringify(data)
  })
  .then(response => response.json())
  .then(data => {
    if (data.success) {
      showStatus('Document signed successfully! Saved to: ' + data.signed_path, 'success');
    } else {
      showStatus('Error: ' + (data.error || 'Unknown error'), 'error');
    }
  })
  .catch(error => {
    showStatus('Error signing document: ' + error.message, 'error');
  })
  .finally(() => {
    document.getElementById('sign-btn').disabled = false;
  });
});

// Show status message
function showStatus(message, type) {
  const statusEl = document.getElementById('status-message');
  statusEl.textContent = message;
  statusEl.style.display = 'block';

  if (type === 'success') {
    statusEl.style.background = '#d4edda';
    statusEl.style.color = '#155724';
    statusEl.style.border = '1px solid #c3e6cb';
  } else if (type === 'error') {
    statusEl.style.background = '#f8d7da';
    statusEl.style.color = '#721c24';
    statusEl.style.border = '1px solid #f5c6cb';
  } else {
    statusEl.style.background = '#d1ecf1';
    statusEl.style.color = '#0c5460';
    statusEl.style.border = '1px solid #bee5eb';
  }

  if (type === 'success' || type === 'error') {
    setTimeout(() => {
      statusEl.style.display = 'none';
    }, 5000);
  }
}

// Initialize
document.addEventListener('DOMContentLoaded', function() {
  loadPDF();
});
