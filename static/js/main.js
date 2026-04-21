/**
 * AgriSense - Main JavaScript File
 */

// Wait for DOM to load
document.addEventListener('DOMContentLoaded', function() {
    // Initialize tooltips
    const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    tooltipTriggerList.map(function (tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl);
    });

    // Initialize popovers
    const popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'));
    popoverTriggerList.map(function (popoverTriggerEl) {
        return new bootstrap.Popover(popoverTriggerEl);
    });

    // Form validation enhancement
    enhanceForms();

    // Auto-save form data
    setupAutoSave();

    // Initialize charts if any
    initializeCharts();
});

/**
 * Enhance forms with better validation and UX
 */
function enhanceForms() {
    const forms = document.querySelectorAll('form');

    forms.forEach(form => {
        // Add live validation
        const inputs = form.querySelectorAll('input, select, textarea');
        inputs.forEach(input => {
            input.addEventListener('blur', function() {
                validateField(this);
            });

            input.addEventListener('input', function() {
                if (this.classList.contains('is-invalid')) {
                    validateField(this);
                }
            });
        });

        // Add form submission confirmation
        form.addEventListener('submit', function(e) {
            form.classList.add('was-submitted');
            const submitBtn = this.querySelector('button[type="submit"]');
            if (submitBtn && !submitBtn.disabled) {
                submitBtn.disabled = true;
                submitBtn.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>Processing...';
            }
        });
    });
}

/**
 * Validate individual form field
 */
function validateField(field) {
    // Clear previous validation
    field.classList.remove('is-invalid', 'is-valid');

    // Get the feedback element or create one
    let feedback = field.nextElementSibling;
    if (!feedback || !feedback.classList.contains('invalid-feedback')) {
        feedback = document.createElement('div');
        feedback.className = 'invalid-feedback';
        field.parentNode.appendChild(feedback);
    }

    // Validation logic
    let isValid = true;
    let message = '';
    const isFileInput = field.type === 'file';
    const form = field.closest('form');
    const hasFiles = isFileInput && field.files && field.files.length > 0;
    const allowFileValidation = !isFileInput || (form && form.classList.contains('was-submitted'));

    // Required validation
    if (field.hasAttribute('required')) {
        if (isFileInput) {
            if (allowFileValidation && !hasFiles) {
                isValid = false;
                message = 'This field is required.';
            }
        } else if (!field.value.trim()) {
            isValid = false;
            message = 'This field is required.';
        }
    }

    // Skip showing invalid state for empty file inputs until submit
    if (isFileInput && !hasFiles && !allowFileValidation) {
        feedback.style.display = 'none';
        return true;
    }

    // Email validation
    if (field.type === 'email' && field.value) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(field.value)) {
            isValid = false;
            message = 'Please enter a valid email address.';
        }
    }

    // Number validation
    if (field.type === 'number' && field.value) {
        const min = parseFloat(field.getAttribute('min'));
        const max = parseFloat(field.getAttribute('max'));
        const value = parseFloat(field.value);

        if (!isNaN(min) && value < min) {
            isValid = false;
            message = `Value must be at least ${min}.`;
        }

        if (!isNaN(max) && value > max) {
            isValid = false;
            message = `Value must be at most ${max}.`;
        }
    }

    // Apply validation state
    if (!isValid) {
        field.classList.add('is-invalid');
        feedback.textContent = message;
        feedback.style.display = 'block';
    } else if (isFileInput ? hasFiles : field.value.trim()) {
        field.classList.add('is-valid');
        feedback.style.display = 'none';
    } else {
        feedback.style.display = 'none';
    }

    return isValid;
}

/**
 * Setup auto-save for form data
 */
function setupAutoSave() {
    const forms = document.querySelectorAll('form[data-autosave]');

    forms.forEach(form => {
        const formId = form.id || 'form_' + Math.random().toString(36).substr(2, 9);

        // Load saved data
        const savedData = localStorage.getItem(`form_${formId}`);
        if (savedData) {
            try {
                const data = JSON.parse(savedData);
                Object.keys(data).forEach(key => {
                    const field = form.querySelector(`[name="${key}"]`);
                    if (field && (field.type !== 'password')) {
                        field.value = data[key];
                        validateField(field);
                    }
                });
            } catch (e) {
                console.error('Error loading saved form data:', e);
            }
        }

        // Save on input
        const saveData = () => {
            const formData = {};
            const inputs = form.querySelectorAll('input, select, textarea');

            inputs.forEach(input => {
                if (input.name && input.type !== 'password') {
                    formData[input.name] = input.value;
                }
            });

            localStorage.setItem(`form_${formId}`, JSON.stringify(formData));
        };

        form.addEventListener('input', saveData);
        form.addEventListener('change', saveData);

        // Clear on successful submit
        form.addEventListener('submit', function() {
            setTimeout(() => {
                localStorage.removeItem(`form_${formId}`);
            }, 1000);
        });
    });
}

/**
 * Initialize simple charts
 */
function initializeCharts() {
    // Check if any chart containers exist
    const chartContainers = document.querySelectorAll('[data-chart]');

    chartContainers.forEach(container => {
        const chartType = container.getAttribute('data-chart') || 'bar';
        const dataAttr = container.getAttribute('data-chart-data');

        if (dataAttr) {
            try {
                const chartData = JSON.parse(dataAttr);
                renderSimpleChart(container, chartType, chartData);
            } catch (e) {
                console.error('Error parsing chart data:', e);
            }
        }
    });
}

/**
 * Render a simple SVG chart
 */
function renderSimpleChart(container, type, data) {
    const width = container.clientWidth || 400;
    const height = container.clientHeight || 300;
    const padding = 40;

    // Create SVG element
    const svgNS = "http://www.w3.org/2000/svg";
    const svg = document.createElementNS(svgNS, "svg");
    svg.setAttribute("width", "100%");
    svg.setAttribute("height", height);
    svg.setAttribute("viewBox", `0 0 ${width} ${height}`);

    // Draw based on chart type
    switch(type) {
        case 'bar':
            drawBarChart(svg, width, height, padding, data);
            break;
        case 'line':
            drawLineChart(svg, width, height, padding, data);
            break;
        case 'pie':
            drawPieChart(svg, width, height, data);
            break;
    }

    container.innerHTML = '';
    container.appendChild(svg);
}

/**
 * Draw a simple bar chart
 */
function drawBarChart(svg, width, height, padding, data) {
    const svgNS = "http://www.w3.org/2000/svg";

    // Calculate scales
    const maxValue = Math.max(...data.values);
    const barWidth = (width - 2 * padding) / data.labels.length * 0.8;
    const barSpacing = (width - 2 * padding) / data.labels.length * 0.2;
    const scaleY = (height - 2 * padding) / maxValue;

    // Draw bars
    data.labels.forEach((label, i) => {
        const x = padding + i * (barWidth + barSpacing);
        const barHeight = data.values[i] * scaleY;
        const y = height - padding - barHeight;

        // Bar
        const bar = document.createElementNS(svgNS, "rect");
        bar.setAttribute("x", x);
        bar.setAttribute("y", y);
        bar.setAttribute("width", barWidth);
        bar.setAttribute("height", barHeight);
        bar.setAttribute("fill", "#28a745");
        bar.setAttribute("rx", "3");
        svg.appendChild(bar);

        // Label
        const text = document.createElementNS(svgNS, "text");
        text.setAttribute("x", x + barWidth / 2);
        text.setAttribute("y", height - padding + 15);
        text.setAttribute("text-anchor", "middle");
        text.setAttribute("font-size", "10");
        text.setAttribute("fill", "#666");
        text.textContent = label;
        svg.appendChild(text);

        // Value
        const valueText = document.createElementNS(svgNS, "text");
        valueText.setAttribute("x", x + barWidth / 2);
        valueText.setAttribute("y", y - 5);
        valueText.setAttribute("text-anchor", "middle");
        valueText.setAttribute("font-size", "10");
        valueText.setAttribute("fill", "#333");
        valueText.textContent = data.values[i];
        svg.appendChild(valueText);
    });

    // Draw axes
    const xAxis = document.createElementNS(svgNS, "line");
    xAxis.setAttribute("x1", padding);
    xAxis.setAttribute("y1", height - padding);
    xAxis.setAttribute("x2", width - padding);
    xAxis.setAttribute("y2", height - padding);
    xAxis.setAttribute("stroke", "#333");
    xAxis.setAttribute("stroke-width", "2");
    svg.appendChild(xAxis);

    const yAxis = document.createElementNS(svgNS, "line");
    yAxis.setAttribute("x1", padding);
    yAxis.setAttribute("y1", padding);
    yAxis.setAttribute("x2", padding);
    yAxis.setAttribute("y2", height - padding);
    yAxis.setAttribute("stroke", "#333");
    yAxis.setAttribute("stroke-width", "2");
    svg.appendChild(yAxis);
}

/**
 * Draw a simple line chart
 */
function drawLineChart(svg, width, height, padding, data) {
    const svgNS = "http://www.w3.org/2000/svg";

    // Calculate scales
    const maxValue = Math.max(...data.values);
    const minValue = Math.min(...data.values);
    const range = maxValue - minValue;
    const scaleY = (height - 2 * padding) / range;
    const scaleX = (width - 2 * padding) / (data.labels.length - 1);

    // Create path for line
    let pathData = `M ${padding} ${height - padding - (data.values[0] - minValue) * scaleY}`;

    data.values.forEach((value, i) => {
        if (i > 0) {
            const x = padding + i * scaleX;
            const y = height - padding - (value - minValue) * scaleY;
            pathData += ` L ${x} ${y}`;
        }
    });

    const line = document.createElementNS(svgNS, "path");
    line.setAttribute("d", pathData);
    line.setAttribute("fill", "none");
    line.setAttribute("stroke", "#28a745");
    line.setAttribute("stroke-width", "3");
    line.setAttribute("stroke-linecap", "round");
    line.setAttribute("stroke-linejoin", "round");
    svg.appendChild(line);

    // Draw points
    data.values.forEach((value, i) => {
        const x = padding + i * scaleX;
        const y = height - padding - (value - minValue) * scaleY;

        const point = document.createElementNS(svgNS, "circle");
        point.setAttribute("cx", x);
        point.setAttribute("cy", y);
        point.setAttribute("r", "4");
        point.setAttribute("fill", "#fff");
        point.setAttribute("stroke", "#28a745");
        point.setAttribute("stroke-width", "2");
        svg.appendChild(point);
    });
}

/**
 * Draw a simple pie chart
 */
function drawPieChart(svg, width, height, data) {
    const svgNS = "http://www.w3.org/2000/svg";
    const centerX = width / 2;
    const centerY = height / 2;
    const radius = Math.min(width, height) / 3;

    let total = data.values.reduce((sum, value) => sum + value, 0);
    let startAngle = 0;

    // Colors for pie segments
    const colors = ['#28a745', '#17a2b8', '#ffc107', '#dc3545', '#6f42c1', '#fd7e14'];

    data.labels.forEach((label, i) => {
        const value = data.values[i];
        const sliceAngle = (value / total) * 2 * Math.PI;
        const endAngle = startAngle + sliceAngle;

        // Calculate arc points
        const startX = centerX + radius * Math.cos(startAngle - Math.PI / 2);
        const startY = centerY + radius * Math.sin(startAngle - Math.PI / 2);
        const endX = centerX + radius * Math.cos(endAngle - Math.PI / 2);
        const endY = centerY + radius * Math.sin(endAngle - Math.PI / 2);

        // Large arc flag
        const largeArcFlag = sliceAngle > Math.PI ? 1 : 0;

        // Create path for pie slice
        const path = document.createElementNS(svgNS, "path");
        const d = [
            `M ${centerX} ${centerY}`,
            `L ${startX} ${startY}`,
            `A ${radius} ${radius} 0 ${largeArcFlag} 1 ${endX} ${endY}`,
            `Z`
        ].join(' ');

        path.setAttribute("d", d);
        path.setAttribute("fill", colors[i % colors.length]);
        path.setAttribute("stroke", "#fff");
        path.setAttribute("stroke-width", "2");
        svg.appendChild(path);

        // Add label
        const labelAngle = startAngle + sliceAngle / 2;
        const labelRadius = radius * 1.2;
        const labelX = centerX + labelRadius * Math.cos(labelAngle - Math.PI / 2);
        const labelY = centerY + labelRadius * Math.sin(labelAngle - Math.PI / 2);

        const text = document.createElementNS(svgNS, "text");
        text.setAttribute("x", labelX);
        text.setAttribute("y", labelY);
        text.setAttribute("text-anchor", "middle");
        text.setAttribute("alignment-baseline", "middle");
        text.setAttribute("font-size", "12");
        text.setAttribute("fill", "#333");
        text.textContent = `${label} (${((value / total) * 100).toFixed(1)}%)`;
        svg.appendChild(text);

        startAngle = endAngle;
    });
}

/**
 * Utility function to format numbers with commas
 */
function formatNumber(num) {
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

/**
 * Utility function to format currency
 */
function formatCurrency(amount, currency = 'Rs.') {
    return `${currency} ${formatNumber(amount.toFixed(2))}`;
}

/**
 * Utility function to download data as CSV
 */
function downloadCSV(filename, data) {
    const csvContent = "data:text/csv;charset=utf-8," + data;
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", filename);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
}

/**
 * Utility function to show toast notifications
 */
function showToast(message, type = 'info') {
    const toastContainer = document.getElementById('toastContainer') || createToastContainer();
    const toastId = 'toast_' + Date.now();

    const toastHtml = `
        <div id="${toastId}" class="toast align-items-center text-bg-${type} border-0" role="alert">
            <div class="d-flex">
                <div class="toast-body">
                    ${message}
                </div>
                <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
            </div>
        </div>
    `;

    toastContainer.innerHTML += toastHtml;
    const toastElement = document.getElementById(toastId);
    const toast = new bootstrap.Toast(toastElement, { delay: 3000 });
    toast.show();

    // Remove toast after it's hidden
    toastElement.addEventListener('hidden.bs.toast', function () {
        this.remove();
    });
}

/**
 * Create toast container if it doesn't exist
 */
function createToastContainer() {
    const container = document.createElement('div');
    container.id = 'toastContainer';
    container.className = 'toast-container position-fixed bottom-0 end-0 p-3';
    container.style.zIndex = '9999';
    document.body.appendChild(container);
    return container;
}

/**
 * Copy text to clipboard
 */
function copyToClipboard(text) {
    navigator.clipboard.writeText(text).then(() => {
        showToast('Copied to clipboard!', 'success');
    }).catch(err => {
        console.error('Failed to copy:', err);
        showToast('Failed to copy to clipboard', 'danger');
    });
}

/**
 * Debounce function for performance
 */
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

/**
 * Throttle function for performance
 */
function throttle(func, limit) {
    let inThrottle;
    return function() {
        const args = arguments;
        const context = this;
        if (!inThrottle) {
            func.apply(context, args);
            inThrottle = true;
            setTimeout(() => inThrottle = false, limit);
        }
    };
}

// Export functions for use in other scripts
window.AgriSense = {
    formatNumber,
    formatCurrency,
    downloadCSV,
    showToast,
    copyToClipboard,
    debounce,
    throttle
};
