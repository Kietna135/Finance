/**
 * FINANCE AI - MINI PROJECT 3 (CORE OCR & CHARTS + CATEGORY & STRICT BUDGET MANAGEMENT)
 * Pure JS, HTML5 Canvas Visualizations, Heuristic Regex Engine, Calendar, Budget & Dynamic Category Manager
 */

// --- 1. CATEGORIES CONFIGURATION & PRESETS ---
const DEFAULT_CATEGORIES = {
  food: { name: 'Ăn uống', icon: 'fa-utensils', color: '#ea580c', bg: '#fff7ed', type: 'expense' },
  daily: { name: 'Chi tiêu h.ngày', icon: 'fa-bottle-droplet', color: '#16a34a', bg: '#f0fdf4', type: 'expense' },
  clothes: { name: 'Quần áo', icon: 'fa-shirt', color: '#2563eb', bg: '#eff6ff', type: 'expense' },
  education: { name: 'Giáo dục & Sách', icon: 'fa-book-open', color: '#0284c7', bg: '#f0f9ff', type: 'expense' },
  transport: { name: 'Đi lại & Xe', icon: 'fa-train-subway', color: '#a16207', bg: '#fefce8', type: 'expense' },
  utility: { name: 'Tiền điện/nước', icon: 'fa-faucet-drip', color: '#0284c7', bg: '#e0f2fe', type: 'expense' },
  rent: { name: 'Tiền nhà', icon: 'fa-house', color: '#059669', bg: '#ecfdf5', type: 'expense' },
  devices: { name: 'Thiết bị & Công nghệ', icon: 'fa-laptop', color: '#9333ea', bg: '#faf5ff', type: 'expense' },
  entertainment: { name: 'Giải trí & Phim', icon: 'fa-film', color: '#db2777', bg: '#fdf2f8', type: 'expense' },
  salary: { name: 'Lương & Thưởng', icon: 'fa-money-bill-wave', color: '#10b981', bg: '#ecfdf5', type: 'income' },
  invest: { name: 'Đầu tư & Tiết kiệm', icon: 'fa-chart-line', color: '#6366f1', bg: '#eef2ff', type: 'income' },
  other: { name: 'Khác', icon: 'fa-receipt', color: '#475569', bg: '#f8fafc', type: 'both' }
};

const AVAILABLE_ICONS = [
  'fa-utensils', 'fa-mug-hot', 'fa-burger', 'fa-bottle-droplet',
  'fa-shirt', 'fa-bag-shopping', 'fa-book-open', 'fa-graduation-cap',
  'fa-train-subway', 'fa-car', 'fa-gas-pump', 'fa-motorcycle',
  'fa-faucet-drip', 'fa-bolt', 'fa-house', 'fa-couch',
  'fa-laptop', 'fa-mobile-screen', 'fa-tv', 'fa-headphones',
  'fa-film', 'fa-gamepad', 'fa-dumbbell', 'fa-paw',
  'fa-gift', 'fa-heart-pulse', 'fa-plane', 'fa-hotel',
  'fa-money-bill-wave', 'fa-coins', 'fa-wallet', 'fa-piggy-bank',
  'fa-chart-line', 'fa-briefcase', 'fa-receipt', 'fa-tags'
];

const PRESET_COLORS = [
  '#ea580c', '#f97316', '#eab308', '#16a34a',
  '#10b981', '#06b6d4', '#0284c7', '#2563eb',
  '#6366f1', '#8b5cf6', '#9333ea', '#db2777',
  '#f43f5e', '#dc2626', '#475569', '#334155'
];

let CATEGORIES = { ...DEFAULT_CATEGORIES };

// Initial Sample Transactions
const INITIAL_TRANSACTIONS = [
  { id: 'exp_1', type: 'expense', merchant: 'WinMart Vincom', amount: 185000, date: '2026-10-08', category: 'food', note: 'Mua thực phẩm & nước ép' },
  { id: 'exp_2', type: 'expense', merchant: 'Nhà sách Fahasa', amount: 240000, date: '2026-10-07', category: 'education', note: 'Giáo trình lập trình & sổ tay' },
  { id: 'exp_3', type: 'expense', merchant: 'Grab Bike', amount: 45000, date: '2026-10-07', category: 'transport', note: 'Di chuyển đến trường' },
  { id: 'exp_4', type: 'expense', merchant: 'Thế Giới Di Động', amount: 350000, date: '2026-10-06', category: 'devices', note: 'Chuột không dây Logitech' },
  { id: 'exp_5', type: 'expense', merchant: 'CGV Cinemas', amount: 130000, date: '2026-10-05', category: 'entertainment', note: 'Vé xem phim cuối tuần' },
  { id: 'exp_6', type: 'expense', merchant: 'Highlands Coffee', amount: 65000, date: '2026-10-04', category: 'food', note: 'Học nhóm đồ án' },
  { id: 'exp_7', type: 'income', merchant: 'Lương thực tập', amount: 3200000, date: '2026-10-01', category: 'salary', note: 'Thù lao dự án tháng 9' }
];

const INITIAL_CATEGORY_BUDGETS = {
  food: 1200000,
  education: 500000,
  transport: 400000,
  devices: 1000000,
  rent: 1200000,
  entertainment: 400000
};

// --- 2. STATE ---
let transactions = [];
let monthlyBudget = 5000000;
let categoryBudgets = { ...INITIAL_CATEGORY_BUDGETS };

let currentFilterCategory = 'all';
let currentSearchQuery = '';
let currentSort = 'date-desc';

// Category Manager State
let currentCatFilter = 'all';
let selectedCategoryIcon = 'fa-utensils';
let selectedCategoryColor = '#ea580c';
let selectedCategoryType = 'expense';

// Chart & Calendar States
let currentBarMode = 'week';
let selectedBarYear = 2026;
let selectedYearRangeLimit = 5;

let currentDonutTime = 'month';
let selectedDonutYear = 2026;
let selectedDonutMonth = 10;

let currentCalYear = 2026;
let currentCalMonth = 10;
let calSelectedDayStr = '2026-10-08';

let manualModalType = 'expense';
let webcamStream = null;

// --- 3. STATE PERSISTENCE ---
function loadState() {
  const storedCats = localStorage.getItem('finance_custom_categories_v2');
  if (storedCats) {
    try {
      CATEGORIES = JSON.parse(storedCats);
    } catch (_) {
      CATEGORIES = { ...DEFAULT_CATEGORIES };
    }
  } else {
    CATEGORIES = { ...DEFAULT_CATEGORIES };
    saveCategories();
  }

  const stored = localStorage.getItem('finance_transactions_v3');
  if (stored) {
    try { transactions = JSON.parse(stored); } catch (_) { transactions = [...INITIAL_TRANSACTIONS]; }
  } else {
    transactions = [...INITIAL_TRANSACTIONS];
    saveState();
  }

  const storedBudget = localStorage.getItem('finance_monthly_budget');
  if (storedBudget) monthlyBudget = Number(storedBudget) || 5000000;

  const storedCatBudgets = localStorage.getItem('finance_cat_budgets');
  if (storedCatBudgets) {
    try { categoryBudgets = JSON.parse(storedCatBudgets); } catch (_) {}
  }
}

function saveState() {
  localStorage.setItem('finance_transactions_v3', JSON.stringify(transactions));
  localStorage.setItem('finance_monthly_budget', monthlyBudget.toString());
  localStorage.setItem('finance_cat_budgets', JSON.stringify(categoryBudgets));
}

function saveCategories() {
  localStorage.setItem('finance_custom_categories_v2', JSON.stringify(CATEGORIES));
}

// --- 4. FORMATTING & HELPER UTILITIES ---
function formatVND(val) {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND', maximumFractionDigits: 0 }).format(val).replace('₫', 'đ');
}

function formatDateVN(dateStr) {
  if (!dateStr) return '';
  const parts = dateStr.split('-');
  if (parts.length === 3) return `${parts[2]}/${parts[1]}/${parts[0]}`;
  return dateStr;
}

function formatDateDisplay(dt) {
  const dayNames = ['CN', 'Th 2', 'Th 3', 'Th 4', 'Th 5', 'Th 6', 'Th 7'];
  const dd = String(dt.getDate()).padStart(2, '0');
  const mm = String(dt.getMonth() + 1).padStart(2, '0');
  const yyyy = dt.getFullYear();
  return `${dd}/${mm}/${yyyy} (${dayNames[dt.getDay()]})`;
}

function findCategory(id) {
  return CATEGORIES[id] || { name: id || 'Khác', icon: 'fa-receipt', color: '#475569', bg: '#f8fafc', type: 'both' };
}

function hexToLightBg(hex) {
  if (!hex || !hex.startsWith('#')) return 'rgba(71, 85, 105, 0.12)';
  const r = parseInt(hex.slice(1, 3), 16) || 0;
  const g = parseInt(hex.slice(3, 5), 16) || 0;
  const b = parseInt(hex.slice(5, 7), 16) || 0;
  return `rgba(${r}, ${g}, ${b}, 0.12)`;
}

function escapeHtml(str) {
  return (str || '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

function getTotalCategoryBudgets(excludeCatId = null) {
  let sum = 0;
  Object.entries(categoryBudgets).forEach(([id, limit]) => {
    if (id !== excludeCatId && limit > 0) {
      sum += limit;
    }
  });
  return sum;
}

// --- 5. RENDER EXPENSE SUMMARY CARD (CORE REQUIREMENT) ---
function renderExpenseSummaryCard(item) {
  const cat = findCategory(item.category);
  const card = document.createElement('div');
  card.className = 'expense-card-item';
  card.setAttribute('data-id', item.id);

  const iconBg = hexToLightBg(cat.color);

  card.innerHTML = `
    <div class="expense-card-left">
      <!-- 1. Icon inside circular container indicating category -->
      <div class="category-icon-circle" style="background:${iconBg}; color:${cat.color};">
        <i class="fa-solid ${cat.icon}"></i>
      </div>
      <!-- 2. Store name and date stacked vertically (CrossAxisAlignment.start) -->
      <div class="expense-meta">
        <span class="expense-merchant">${escapeHtml(item.merchant || 'Chưa xác định')}</span>
        <span class="expense-date">
          <i class="fa-regular fa-calendar"></i> ${formatDateVN(item.date)}
        </span>
      </div>
    </div>
    <div class="expense-card-right">
      <!-- 3. Highlighted monetary amount formatted as VND (###.### đ) -->
      <span class="expense-amount-highlight ${item.type === 'income' ? 'income-val' : ''}">
        ${item.type === 'income' ? '+' : ''}${formatVND(item.amount)}
      </span>
      <button class="delete-btn" title="Xóa giao dịch" data-delete-id="${item.id}">
        <i class="fa-solid fa-trash-can"></i>
      </button>
    </div>
  `;

  // Tap callback to edit
  card.addEventListener('click', (e) => {
    if (e.target.closest('.delete-btn')) return;
    openEditModal(item);
  });

  return card;
}

// --- 6. CATEGORY MANAGEMENT FUNCTIONS ---
function renderCategoryChips() {
  const container = document.getElementById('categoryChips');
  if (!container) return;
  container.innerHTML = '';

  const allBtn = document.createElement('button');
  allBtn.className = `chip ${currentFilterCategory === 'all' ? 'active' : ''}`;
  allBtn.dataset.category = 'all';
  allBtn.textContent = 'Tất cả';
  allBtn.addEventListener('click', () => {
    currentFilterCategory = 'all';
    document.querySelectorAll('#categoryChips .chip').forEach(c => c.classList.remove('active'));
    allBtn.classList.add('active');
    renderFullTransactionsList();
  });
  container.appendChild(allBtn);

  Object.entries(CATEGORIES).forEach(([id, cat]) => {
    const chip = document.createElement('button');
    chip.className = `chip ${currentFilterCategory === id ? 'active' : ''}`;
    chip.dataset.category = id;
    chip.innerHTML = `<i class="fa-solid ${cat.icon}" style="color:${cat.color}"></i> ${cat.name}`;
    chip.addEventListener('click', () => {
      currentFilterCategory = id;
      document.querySelectorAll('#categoryChips .chip').forEach(c => c.classList.remove('active'));
      chip.classList.add('active');
      renderFullTransactionsList();
    });
    container.appendChild(chip);
  });
}

function renderCategoryRadioGroup(containerId, inputName, selectedCat, filterType = null) {
  const container = document.getElementById(containerId);
  if (!container) return;
  container.innerHTML = '';

  let entries = Object.entries(CATEGORIES);
  if (filterType === 'expense') {
    entries = entries.filter(([_, cat]) => cat.type === 'expense' || cat.type === 'both' || !cat.type);
  } else if (filterType === 'income') {
    entries = entries.filter(([_, cat]) => cat.type === 'income' || cat.type === 'both' || !cat.type);
  }

  entries.forEach(([id, cat]) => {
    const isChecked = id === selectedCat;
    const label = document.createElement('label');
    label.className = 'cat-radio-label';
    const bg = hexToLightBg(cat.color);
    label.innerHTML = `
      <input type="radio" name="${inputName}" value="${id}" ${isChecked ? 'checked' : ''}>
      <span class="cat-badge" style="background:${bg}; color:${cat.color};">
        <i class="fa-solid ${cat.icon}"></i> ${escapeHtml(cat.name)}
      </span>
    `;
    container.appendChild(label);
  });
}

function renderCategoryManagerList(filter = 'all') {
  const list = document.getElementById('categoryManagerList');
  if (!list) return;
  list.innerHTML = '';

  let entries = Object.entries(CATEGORIES);
  if (filter === 'expense') {
    entries = entries.filter(([_, cat]) => cat.type === 'expense' || cat.type === 'both');
  } else if (filter === 'income') {
    entries = entries.filter(([_, cat]) => cat.type === 'income' || cat.type === 'both');
  }

  if (entries.length === 0) {
    list.innerHTML = `<div style="grid-column: 1/-1; text-align:center; padding: 24px; color: var(--text-muted);">Không có danh mục nào trong mục này</div>`;
    return;
  }

  entries.forEach(([id, cat]) => {
    const card = document.createElement('div');
    card.className = 'cat-manager-card';
    const bg = hexToLightBg(cat.color);
    const typeLabel = cat.type === 'expense' ? 'Chi tiêu' : (cat.type === 'income' ? 'Thu nhập' : 'Cả hai');
    const typeClass = cat.type || 'expense';

    card.innerHTML = `
      <div class="cat-card-info">
        <div class="category-icon-circle" style="background:${bg}; color:${cat.color}; width:38px; height:38px; font-size:16px;">
          <i class="fa-solid ${cat.icon}"></i>
        </div>
        <div>
          <div class="cat-card-name" title="${escapeHtml(cat.name)}">${escapeHtml(cat.name)}</div>
          <span class="cat-card-type-badge ${typeClass}">${typeLabel}</span>
        </div>
      </div>
      <div class="cat-card-actions">
        <button class="cat-action-btn edit-cat-btn" title="Chỉnh sửa danh mục" data-cat-id="${id}">
          <i class="fa-solid fa-pen"></i>
        </button>
        <button class="cat-action-btn del-btn delete-cat-btn" title="Xóa danh mục" data-cat-id="${id}" ${id === 'other' ? 'disabled style="opacity:0.4; cursor:not-allowed;"' : ''}>
          <i class="fa-solid fa-trash-can"></i>
        </button>
      </div>
    `;

    // Edit button click
    card.querySelector('.edit-cat-btn').addEventListener('click', () => {
      openEditCategoryModal(id);
    });

    // Delete button click
    if (id !== 'other') {
      card.querySelector('.delete-cat-btn').addEventListener('click', () => {
        deleteCategory(id);
      });
    }

    list.appendChild(card);
  });
}

function populateIconPicker(selectedIcon) {
  const grid = document.getElementById('iconPickerGrid');
  if (!grid) return;
  grid.innerHTML = '';

  AVAILABLE_ICONS.forEach(icon => {
    const btn = document.createElement('button');
    btn.type = 'button';
    btn.className = `icon-choice-btn ${icon === selectedIcon ? 'active' : ''}`;
    btn.innerHTML = `<i class="fa-solid ${icon}"></i>`;
    btn.title = icon;
    btn.addEventListener('click', () => {
      selectedCategoryIcon = icon;
      document.querySelectorAll('.icon-choice-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      updateCategoryLivePreview();
    });
    grid.appendChild(btn);
  });
}

function populateColorPalette(selectedColor) {
  const palette = document.getElementById('colorPickerPalette');
  if (!palette) return;
  palette.innerHTML = '';

  PRESET_COLORS.forEach(color => {
    const btn = document.createElement('button');
    btn.type = 'button';
    btn.className = `color-swatch-btn ${color.toLowerCase() === selectedColor.toLowerCase() ? 'active' : ''}`;
    btn.style.backgroundColor = color;
    btn.title = color;
    btn.addEventListener('click', () => {
      selectedCategoryColor = color;
      document.querySelectorAll('.color-swatch-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      updateCategoryLivePreview();
    });
    palette.appendChild(btn);
  });

  // Custom Color Input
  const customWrapper = document.createElement('div');
  customWrapper.className = 'custom-color-input-wrapper';
  customWrapper.innerHTML = `
    <span style="font-size:11px; font-weight:700; color:var(--text-muted);">Tùy chỉnh:</span>
    <input type="color" id="customCatColorPicker" value="${selectedColor}">
  `;
  customWrapper.querySelector('#customCatColorPicker').addEventListener('input', (e) => {
    selectedCategoryColor = e.target.value;
    document.querySelectorAll('.color-swatch-btn').forEach(b => b.classList.remove('active'));
    updateCategoryLivePreview();
  });
  palette.appendChild(customWrapper);
}

function updateCategoryLivePreview() {
  const nameInput = document.getElementById('categoryNameInput');
  const name = (nameInput?.value.trim()) || 'Tên danh mục';
  const previewBox = document.getElementById('categoryLivePreview');
  const previewIconBox = document.getElementById('previewIconBox');
  const previewIconEl = document.getElementById('previewIconEl');
  const previewNameEl = document.getElementById('previewNameEl');

  if (previewIconEl) {
    previewIconEl.className = `fa-solid ${selectedCategoryIcon}`;
  }
  if (previewNameEl) {
    previewNameEl.textContent = name;
  }
  if (previewBox && previewIconBox) {
    const bg = hexToLightBg(selectedCategoryColor);
    previewBox.style.backgroundColor = bg;
    previewBox.style.borderColor = selectedCategoryColor;
    previewIconBox.style.backgroundColor = selectedCategoryColor;
    previewIconBox.style.color = '#ffffff';
    previewNameEl.style.color = selectedCategoryColor;
  }
}

function openAddCategoryModal() {
  document.getElementById('addEditCategoryTitle').innerHTML = '<i class="fa-solid fa-folder-plus"></i> Thêm Danh Mục Mới';
  document.getElementById('addEditCategoryForm').reset();
  document.getElementById('editCategoryId').value = '';

  selectedCategoryIcon = 'fa-utensils';
  selectedCategoryColor = '#ea580c';
  selectedCategoryType = 'expense';

  document.getElementById('catTypeExpense').classList.add('active');
  document.getElementById('catTypeIncome').classList.remove('active');
  document.getElementById('catTypeBoth').classList.remove('active');

  populateIconPicker(selectedCategoryIcon);
  populateColorPalette(selectedCategoryColor);
  updateCategoryLivePreview();
  openModal('addEditCategoryModal');
}

function openEditCategoryModal(catId) {
  const cat = CATEGORIES[catId];
  if (!cat) return;

  document.getElementById('addEditCategoryTitle').innerHTML = '<i class="fa-solid fa-pen-to-square"></i> Chỉnh Sửa Danh Mục';
  document.getElementById('editCategoryId').value = catId;
  document.getElementById('categoryNameInput').value = cat.name;

  selectedCategoryIcon = cat.icon || 'fa-utensils';
  selectedCategoryColor = cat.color || '#ea580c';
  selectedCategoryType = cat.type || 'expense';

  document.getElementById('catTypeExpense').classList.toggle('active', selectedCategoryType === 'expense');
  document.getElementById('catTypeIncome').classList.toggle('active', selectedCategoryType === 'income');
  document.getElementById('catTypeBoth').classList.toggle('active', selectedCategoryType === 'both');

  populateIconPicker(selectedCategoryIcon);
  populateColorPalette(selectedCategoryColor);
  updateCategoryLivePreview();
  openModal('addEditCategoryModal');
}

function deleteCategory(catId) {
  if (catId === 'other') {
    alert('Không thể xóa danh mục mặc định "Khác".');
    return;
  }

  const catName = CATEGORIES[catId]?.name || catId;
  const count = transactions.filter(t => t.category === catId).length;

  let msg = `Bạn có chắc muốn xóa danh mục "${catName}"?`;
  if (count > 0) {
    msg += `\nHiện có ${count} giao dịch đang thuộc danh mục này. Chúng sẽ được chuyển sang danh mục "Khác".`;
  }

  if (confirm(msg)) {
    // Reassign transactions
    transactions.forEach(t => {
      if (t.category === catId) {
        t.category = 'other';
      }
    });

    // Delete category
    delete CATEGORIES[catId];
    delete categoryBudgets[catId];

    saveCategories();
    saveState();

    renderCategoryManagerList(currentCatFilter);
    renderCategoryChips();
    updateUI();
  }
}

// --- 7. INDIVIDUAL CATEGORY BUDGET MANAGEMENT WITH STRICT SUM VALIDATION ---
function openCategoryBudgetModal(catId = null) {
  const form = document.getElementById('categoryBudgetForm');
  form.reset();

  const selectGroup = document.getElementById('catBudgetSelectGroup');
  const infoBox = document.getElementById('catBudgetInfoBox');
  const select = document.getElementById('catBudgetSelect');
  const removeBtn = document.getElementById('removeCatBudgetBtn');
  const modalTitle = document.getElementById('catBudgetModalTitle');
  const amountInput = document.getElementById('catBudgetAmountInput');

  // Month expenses
  const currentMonthPrefix = `2026-10`;
  const monthExpenses = transactions.filter(t => t.type === 'expense' && t.date && t.date.startsWith(currentMonthPrefix));
  const catSpent = {};
  monthExpenses.forEach(t => catSpent[t.category] = (catSpent[t.category] || 0) + t.amount);

  let targetCatId = catId;

  if (catId && CATEGORIES[catId]) {
    // Edit existing category budget
    const cat = findCategory(catId);
    const currentLimit = categoryBudgets[catId] || 0;
    const spent = catSpent[catId] || 0;
    const remaining = Math.max(0, currentLimit - spent);

    document.getElementById('catBudgetId').value = catId;
    modalTitle.innerHTML = `<i class="fa-solid fa-sliders"></i> Hạn Mức: ${escapeHtml(cat.name)}`;
    selectGroup.style.display = 'none';
    infoBox.classList.remove('hidden');

    const iconBg = hexToLightBg(cat.color);
    document.getElementById('catBudgetIconBox').style.backgroundColor = iconBg;
    document.getElementById('catBudgetIconBox').style.color = cat.color;
    document.getElementById('catBudgetIconEl').className = `fa-solid ${cat.icon}`;
    document.getElementById('catBudgetNameEl').textContent = cat.name;
    document.getElementById('catBudgetSpentEl').textContent = `Đã chi: ${formatVND(spent)}`;
    document.getElementById('catBudgetRemainingEl').textContent = `Còn lại: ${formatVND(remaining)}`;

    amountInput.value = currentLimit || '';
    removeBtn.style.display = currentLimit > 0 ? 'inline-flex' : 'none';
  } else {
    // Add budget for category
    modalTitle.innerHTML = `<i class="fa-solid fa-sliders"></i> Đặt Hạn Mức Cho Danh Mục`;
    document.getElementById('catBudgetId').value = '';
    selectGroup.style.display = 'block';
    infoBox.classList.add('hidden');
    removeBtn.style.display = 'none';

    // Populate category select
    select.innerHTML = '';
    const expenseCategories = Object.entries(CATEGORIES).filter(([_, c]) => c.type === 'expense' || c.type === 'both' || !c.type);
    expenseCategories.forEach(([id, c]) => {
      const opt = document.createElement('option');
      opt.value = id;
      const currentLim = categoryBudgets[id] ? ` (Đang đặt: ${formatVND(categoryBudgets[id])})` : '';
      opt.textContent = `${c.name}${currentLim}`;
      select.appendChild(opt);
    });

    if (expenseCategories.length > 0) {
      targetCatId = expenseCategories[0][0];
      amountInput.value = categoryBudgets[targetCatId] || '';
    }
  }

  updateCategoryBudgetLimitGuidance(targetCatId);
  openModal('categoryBudgetModal');
}

function updateCategoryBudgetLimitGuidance(currentEditingCatId) {
  const otherSum = getTotalCategoryBudgets(currentEditingCatId);
  const maxAvailable = Math.max(0, monthlyBudget - otherSum);

  document.getElementById('guideMonthlyBudget').textContent = formatVND(monthlyBudget);
  document.getElementById('guideOtherBudgets').textContent = formatVND(otherSum);
  document.getElementById('guideMaxAvailable').textContent = formatVND(maxAvailable);

  validateCategoryBudgetInput(maxAvailable);
}

function validateCategoryBudgetInput(maxAvailable) {
  const input = document.getElementById('catBudgetAmountInput');
  const val = parseFloat(input.value) || 0;
  const warningBox = document.getElementById('catBudgetWarningBox');
  const warningMsg = document.getElementById('catBudgetWarningMsg');
  const saveBtn = document.getElementById('saveCatBudgetBtn');

  if (val > maxAvailable) {
    const excess = val - maxAvailable;
    warningMsg.innerHTML = `Số tiền (${formatVND(val)}) vượt quá mức tối đa cho phép (${formatVND(maxAvailable)}) là <strong>${formatVND(excess)}</strong>. Tổng các danh mục không được vượt quá Tổng ngân sách (${formatVND(monthlyBudget)})!`;
    warningBox.classList.remove('hidden');
    saveBtn.disabled = true;
  } else {
    warningBox.classList.add('hidden');
    saveBtn.disabled = false;
  }
}

// Master Budget Modal Allocation Tracker & Live Validation
function populateMasterBudgetModal() {
  document.getElementById('monthlyBudgetInput').value = monthlyBudget;
  const listContainer = document.getElementById('modalCategoryBudgetsList');
  if (!listContainer) return;
  listContainer.innerHTML = '';

  const expenseCategories = Object.entries(CATEGORIES).filter(([_, c]) => c.type === 'expense' || c.type === 'both' || !c.type);

  expenseCategories.forEach(([catId, cat]) => {
    const limit = categoryBudgets[catId] || 0;
    const bg = hexToLightBg(cat.color);

    const row = document.createElement('div');
    row.className = 'modal-cat-budget-row';
    row.innerHTML = `
      <div class="modal-cat-budget-info">
        <div class="category-icon-circle" style="background:${bg}; color:${cat.color}; width:32px; height:32px; font-size:14px;">
          <i class="fa-solid ${cat.icon}"></i>
        </div>
        <span style="font-size:13px; font-weight:700;">${escapeHtml(cat.name)}</span>
      </div>
      <div class="modal-cat-budget-input-box">
        <input type="number" class="modal-cat-limit-input" data-cat-id="${catId}" value="${limit}" min="0" step="50000" placeholder="0">
        <span style="font-size:12px; font-weight:700; color:var(--text-muted);">đ</span>
      </div>
    `;
    listContainer.appendChild(row);
  });

  // Attach live validation on all category inputs
  listContainer.querySelectorAll('.modal-cat-limit-input').forEach(inp => {
    inp.addEventListener('input', updateMasterModalAllocationTracker);
  });
  document.getElementById('monthlyBudgetInput').addEventListener('input', updateMasterModalAllocationTracker);

  updateMasterModalAllocationTracker();
  openModal('budgetModal');
}

function updateMasterModalAllocationTracker() {
  const masterVal = parseFloat(document.getElementById('monthlyBudgetInput').value) || 0;
  let allocatedSum = 0;
  document.querySelectorAll('.modal-cat-limit-input').forEach(inp => {
    allocatedSum += parseFloat(inp.value) || 0;
  });

  const percent = masterVal > 0 ? ((allocatedSum / masterVal) * 100) : 0;
  const bar = document.getElementById('modalAllocatedBar');
  const sumText = document.getElementById('modalAllocatedSumText');
  const unallocatedText = document.getElementById('modalUnallocatedText');
  const statusBadge = document.getElementById('modalAllocationStatusBadge');
  const warningBox = document.getElementById('modalAllocationWarningBox');
  const warningMsg = document.getElementById('modalAllocationWarningMsg');
  const saveBtn = document.getElementById('saveMasterBudgetBtn');

  sumText.textContent = `${formatVND(allocatedSum)} / ${formatVND(masterVal)} (${percent.toFixed(0)}%)`;
  bar.style.width = Math.min(100, percent) + '%';

  if (allocatedSum > masterVal) {
    const excess = allocatedSum - masterVal;
    bar.style.backgroundColor = 'var(--expense-red)';
    statusBadge.textContent = '❌ Vượt ngân sách';
    statusBadge.style.color = 'var(--expense-red)';
    unallocatedText.textContent = `Bị vượt mức: -${formatVND(excess)}`;
    unallocatedText.style.color = 'var(--expense-red)';

    warningMsg.innerHTML = `Tổng hạn mức các danh mục (<strong>${formatVND(allocatedSum)}</strong>) đang vượt quá Tổng ngân sách (<strong>${formatVND(masterVal)}</strong>) là <strong>${formatVND(excess)}</strong>! Vui lòng giảm hạn mức danh mục hoặc tăng tổng ngân sách.`;
    warningBox.classList.remove('hidden');
    saveBtn.disabled = true;
  } else {
    const remaining = masterVal - allocatedSum;
    bar.style.backgroundColor = 'var(--primary)';
    statusBadge.textContent = '✅ Hợp lệ';
    statusBadge.style.color = 'var(--net-green)';
    unallocatedText.textContent = `Khả dụng chưa phân bổ: ${formatVND(remaining)}`;
    unallocatedText.style.color = 'var(--text-muted)';

    warningBox.classList.add('hidden');
    saveBtn.disabled = false;
  }
}

// --- 8. RENDER DASHBOARD & LISTS ---
function updateUI() {
  const currentMonthPrefix = `2026-10`;
  const monthExpenses = transactions.filter(t => t.type === 'expense' && t.date && t.date.startsWith(currentMonthPrefix));
  const monthSpent = monthExpenses.reduce((sum, e) => sum + e.amount, 0);

  // Dashboard Balance
  document.getElementById('dashTotalSpent').textContent = formatVND(monthSpent);
  document.getElementById('dashBudgetLimit').textContent = formatVND(monthlyBudget);

  const percent = monthlyBudget > 0 ? (monthSpent / monthlyBudget) * 100 : 0;
  const clampedPercent = Math.min(100, percent);
  const remaining = Math.max(0, monthlyBudget - monthSpent);

  const progressBar = document.getElementById('dashProgressBar');
  progressBar.style.width = clampedPercent + '%';
  progressBar.className = 'progress-bar';
  if (percent >= 90) progressBar.classList.add('danger');
  else if (percent >= 70) progressBar.classList.add('warning');

  document.getElementById('dashBudgetPercent').textContent = `Đã dùng: ${percent.toFixed(1)}%`;
  document.getElementById('dashBudgetRemaining').textContent = `Còn lại: ${formatVND(remaining)}`;

  // Render recent 4 items on Dashboard
  const recentList = document.getElementById('recentExpenseList');
  recentList.innerHTML = '';
  const sorted = [...transactions].sort((a, b) => new Date(b.date) - new Date(a.date));

  if (sorted.length === 0) {
    recentList.innerHTML = `<div style="text-align:center; padding: 20px; color: var(--text-muted);">Chưa có chi tiêu nào. Bấm "Quét Hóa Đơn AI" để thêm!</div>`;
  } else {
    sorted.slice(0, 4).forEach(item => {
      recentList.appendChild(renderExpenseSummaryCard(item));
    });
  }

  // Render Category Filter Chips & Full Transactions List
  renderCategoryChips();
  renderFullTransactionsList();

  // Populate dynamic Year select
  populateYearSelectOptions();
  updateDonutPeriodUI();

  // Draw Custom Canvas Charts
  drawWeeklyBarChart('weeklyBarCanvasMini', 480, 200, false, 'week');
  drawCategoryDonutChart('categoryDonutCanvasMini', 480, 200, true);
  drawWeeklyBarChart('weeklyBarCanvasFull', 560, 260, true);
  drawCategoryDonutChart('categoryDonutCanvasFull', 360, 360, false);
  renderCategoryBreakdownList();

  // Render Calendar & Budget screens
  renderCalendarScreen();
  renderBudgetScreen();
}

function renderFullTransactionsList() {
  const fullList = document.getElementById('fullExpenseList');
  if (!fullList) return;
  fullList.innerHTML = '';

  let filtered = [...transactions];

  if (currentFilterCategory !== 'all') {
    filtered = filtered.filter(e => e.category === currentFilterCategory);
  }

  if (currentSearchQuery.trim() !== '') {
    const q = currentSearchQuery.toLowerCase().trim();
    filtered = filtered.filter(e =>
      e.merchant.toLowerCase().includes(q) ||
      (e.note && e.note.toLowerCase().includes(q)) ||
      (CATEGORIES[e.category] && CATEGORIES[e.category].name.toLowerCase().includes(q))
    );
  }

  // Sort
  if (currentSort === 'date-desc') filtered.sort((a, b) => new Date(b.date) - new Date(a.date));
  else if (currentSort === 'date-asc') filtered.sort((a, b) => new Date(a.date) - new Date(b.date));
  else if (currentSort === 'amount-desc') filtered.sort((a, b) => b.amount - a.amount);
  else if (currentSort === 'amount-asc') filtered.sort((a, b) => a.amount - b.amount);

  if (filtered.length === 0) {
    fullList.innerHTML = `<div style="text-align:center; padding: 30px; color: var(--text-muted);">Không tìm thấy giao dịch phù hợp</div>`;
    return;
  }

  filtered.forEach(item => {
    fullList.appendChild(renderExpenseSummaryCard(item));
  });
}

// --- 9. CALENDAR SCREEN LOGIC ---
function renderCalendarScreen() {
  const title = document.getElementById('calPeriodTitle');
  if (title) title.textContent = `${String(currentCalMonth).padStart(2, '0')}/${currentCalYear}`;

  const grid = document.getElementById('calendarDaysGrid');
  if (!grid) return;
  grid.innerHTML = '';

  const firstDay = new Date(currentCalYear, currentCalMonth - 1, 1);
  const lastDay = new Date(currentCalYear, currentCalMonth, 0);
  const totalDays = lastDay.getDate();

  let startDayOfWeek = firstDay.getDay();
  let leadingBlanks = startDayOfWeek === 0 ? 6 : startDayOfWeek - 1;
  const prevMonthLastDay = new Date(currentCalYear, currentCalMonth - 1, 0).getDate();

  const dayMap = {};
  let monthIncome = 0;
  let monthExpense = 0;

  transactions.forEach(t => {
    if (t.date && t.date.startsWith(`${currentCalYear}-${String(currentCalMonth).padStart(2, '0')}`)) {
      if (!dayMap[t.date]) dayMap[t.date] = { expense: 0, income: 0, items: [] };
      if (t.type === 'income') {
        dayMap[t.date].income += t.amount;
        monthIncome += t.amount;
      } else {
        dayMap[t.date].expense += t.amount;
        monthExpense += t.amount;
      }
      dayMap[t.date].items.push(t);
    }
  });

  document.getElementById('calTotalIncome').textContent = `+${formatVND(monthIncome)}`;
  document.getElementById('calTotalExpense').textContent = `-${formatVND(monthExpense)}`;
  const net = monthIncome - monthExpense;
  document.getElementById('calTotalNet').textContent = (net >= 0 ? '+' : '-') + formatVND(net);

  for (let i = leadingBlanks - 1; i >= 0; i--) {
    const cell = document.createElement('div');
    cell.className = 'cal-day-cell other-month';
    cell.innerHTML = `<span class="cal-day-num">${prevMonthLastDay - i}</span>`;
    grid.appendChild(cell);
  }

  for (let d = 1; d <= totalDays; d++) {
    const dateStr = `${currentCalYear}-${String(currentCalMonth).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
    const dayData = dayMap[dateStr];
    const isSelected = dateStr === calSelectedDayStr;

    const cell = document.createElement('div');
    cell.className = `cal-day-cell ${isSelected ? 'selected' : ''}`;

    let content = `<span class="cal-day-num">${d}</span>`;
    if (dayData) {
      if (dayData.income > 0) content += `<span class="cal-income-val">+${new Intl.NumberFormat('vi-VN').format(dayData.income)}</span>`;
      if (dayData.expense > 0) content += `<span class="cal-spent-val">-${new Intl.NumberFormat('vi-VN').format(dayData.expense)}</span>`;
    }

    cell.innerHTML = content;
    cell.addEventListener('click', () => {
      calSelectedDayStr = dateStr;
      renderCalendarScreen();
    });

    grid.appendChild(cell);
  }

  renderCalendarDayTransactions();
}

function renderCalendarDayTransactions() {
  const listContainer = document.getElementById('calendarDayList');
  const label = document.getElementById('selectedDayLabel');
  const totalBadge = document.getElementById('selectedDayTotal');
  if (!listContainer) return;
  listContainer.innerHTML = '';

  const dayParts = calSelectedDayStr.split('-');
  const dt = new Date(Number(dayParts[0]), Number(dayParts[1]) - 1, Number(dayParts[2]));
  if (label) label.textContent = formatDateDisplay(dt);

  const dayItems = transactions.filter(t => t.date === calSelectedDayStr);
  const dayTotal = dayItems.reduce((s, t) => s + (t.type === 'expense' ? -t.amount : t.amount), 0);
  if (totalBadge) totalBadge.textContent = (dayTotal >= 0 ? '+' : '-') + formatVND(dayTotal);

  if (dayItems.length === 0) {
    listContainer.innerHTML = `<div style="text-align:center; padding: 16px; color: var(--text-muted); font-size: 13px;">Không có giao dịch trong ngày này</div>`;
    return;
  }

  dayItems.forEach(t => {
    listContainer.appendChild(renderExpenseSummaryCard(t));
  });
}

// --- 10. BUDGET SCREEN LOGIC ---
function renderBudgetScreen() {
  const currentMonthPrefix = `2026-10`;
  const monthExpenses = transactions.filter(t => t.type === 'expense' && t.date && t.date.startsWith(currentMonthPrefix));
  const monthSpent = monthExpenses.reduce((sum, e) => sum + e.amount, 0);

  const masterRemaining = Math.max(0, monthlyBudget - monthSpent);
  const masterPercent = monthlyBudget > 0 ? Math.min(100, (monthSpent / monthlyBudget) * 100) : 0;

  document.getElementById('budgetScreenRemaining').textContent = formatVND(masterRemaining);
  document.getElementById('budgetScreenLimit').textContent = `Ngân sách: ${formatVND(monthlyBudget)}`;
  document.getElementById('budgetScreenSpent').textContent = `Đã chi: ${formatVND(monthSpent)} (${masterPercent.toFixed(0)}%)`;

  const bar = document.getElementById('budgetScreenBar');
  if (bar) {
    bar.style.width = `${masterPercent}%`;
    bar.className = 'progress-bar';
    if (masterPercent >= 90) bar.classList.add('danger');
    else if (masterPercent >= 70) bar.classList.add('warning');
  }

  // Render Allocation Summary Card (Total Category Budgets <= Monthly Budget)
  const totalCatBudgets = getTotalCategoryBudgets();
  const allocationPercent = monthlyBudget > 0 ? ((totalCatBudgets / monthlyBudget) * 100) : 0;
  const unallocated = Math.max(0, monthlyBudget - totalCatBudgets);

  const allocStatusText = document.getElementById('allocationStatusText');
  const allocBar = document.getElementById('allocationProgressBar');
  const unallocText = document.getElementById('unallocatedBudgetText');

  if (allocStatusText) {
    allocStatusText.textContent = `Đã phân bổ: ${formatVND(totalCatBudgets)} / ${formatVND(monthlyBudget)} (${allocationPercent.toFixed(0)}%)`;
  }
  if (allocBar) {
    allocBar.style.width = Math.min(100, allocationPercent) + '%';
    allocBar.style.backgroundColor = totalCatBudgets > monthlyBudget ? 'var(--expense-red)' : 'var(--primary)';
  }
  if (unallocText) {
    unallocText.textContent = `Khả dụng chưa phân bổ: ${formatVND(unallocated)}`;
  }

  const listContainer = document.getElementById('categoryBudgetsList');
  if (!listContainer) return;
  listContainer.innerHTML = '';

  const catSpent = {};
  monthExpenses.forEach(t => catSpent[t.category] = (catSpent[t.category] || 0) + t.amount);

  const budgetEntries = Object.entries(categoryBudgets).filter(([_, limit]) => limit > 0);

  if (budgetEntries.length === 0) {
    listContainer.innerHTML = `
      <div style="text-align:center; padding: 32px 16px; color: var(--text-muted); background: var(--bg-surface); border-radius: var(--radius-md);">
        <i class="fa-solid fa-wallet" style="font-size: 28px; margin-bottom: 8px; opacity: 0.5;"></i>
        <p style="font-size: 14px; font-weight: 600;">Chưa thiết lập hạn mức cho danh mục nào.</p>
        <button class="btn btn-primary btn-sm" id="emptyAddBudgetBtn" style="margin-top: 10px;">
          <i class="fa-solid fa-plus"></i> Đặt hạn mức danh mục ngay
        </button>
      </div>
    `;
    document.getElementById('emptyAddBudgetBtn')?.addEventListener('click', () => openCategoryBudgetModal());
    return;
  }

  budgetEntries.forEach(([catId, limit]) => {
    const cat = findCategory(catId);
    const spent = catSpent[catId] || 0;
    const remaining = Math.max(0, limit - spent);
    const percent = limit > 0 ? Math.min(100, (spent / limit) * 100) : 0;
    const bg = hexToLightBg(cat.color);

    const card = document.createElement('div');
    card.className = 'category-budget-row-card';

    card.innerHTML = `
      <div style="display:flex; justify-content:space-between; align-items:center;">
        <div style="display:flex; align-items:center; gap:10px;">
          <div class="category-icon-circle" style="background:${bg}; color:${cat.color}; width:38px; height:38px; font-size:16px;">
            <i class="fa-solid ${cat.icon}"></i>
          </div>
          <div>
            <span style="font-weight:700; font-size:14px;">${escapeHtml(cat.name)}</span>
            <div style="font-size:11px; color:var(--text-muted); margin-top:2px;">
              Hạn mức: <strong style="color:var(--text-main);">${formatVND(limit)}</strong>
            </div>
          </div>
        </div>
        <div class="cat-budget-header-actions">
          <div style="font-size:13px; text-align:right; margin-right:4px;">
            <span style="font-size:11px; color:var(--text-muted);">Còn lại: </span>
            <strong style="color:${remaining > 0 ? 'var(--primary)' : 'var(--expense-red)'}; font-weight:800;">${formatVND(remaining)}</strong>
          </div>
          <button class="cat-budget-edit-btn edit-cat-budget-trigger" title="Chỉnh sửa hạn mức ${escapeHtml(cat.name)}" data-cat-id="${catId}">
            <i class="fa-solid fa-pen"></i>
          </button>
          <button class="cat-budget-edit-btn del-btn remove-cat-budget-trigger" title="Xóa hạn mức ${escapeHtml(cat.name)}" data-cat-id="${catId}">
            <i class="fa-solid fa-trash-can"></i>
          </button>
        </div>
      </div>
      <div class="progress-track" style="margin:0; height:8px;">
        <div class="progress-bar ${percent >= 90 ? 'danger' : (percent >= 70 ? 'warning' : '')}" style="width:${percent}%; background:${cat.color};"></div>
      </div>
      <div style="display:flex; justify-content:space-between; font-size:11px; color:var(--text-muted);">
        <span>Đã chi: ${formatVND(spent)} (${percent.toFixed(0)}%)</span>
        <span>${percent >= 100 ? '⚠️ Đã vượt hạn mức!' : `Còn ${ (100 - percent).toFixed(0) }% ngân sách`}</span>
      </div>
    `;

    // Click on Edit button
    card.querySelector('.edit-cat-budget-trigger').addEventListener('click', (e) => {
      e.stopPropagation();
      openCategoryBudgetModal(catId);
    });

    // Click on Delete budget limit button
    card.querySelector('.remove-cat-budget-trigger').addEventListener('click', (e) => {
      e.stopPropagation();
      if (confirm(`Bạn có chắc muốn xóa hạn mức của danh mục "${cat.name}"?`)) {
        delete categoryBudgets[catId];
        saveState();
        updateUI();
      }
    });

    // Click on card opens edit modal
    card.addEventListener('click', () => {
      openCategoryBudgetModal(catId);
    });

    listContainer.appendChild(card);
  });
}

// --- 11. CUSTOM CANVAS CHARTS (WEEKLY / MONTHLY / YEARLY & DONUT) ---
function updateDonutPeriodUI() {
  const label = document.getElementById('donutCurrentPeriodLabel');
  if (!label) return;

  if (currentDonutTime === 'all') label.textContent = 'Toàn bộ thời gian';
  else if (currentDonutTime === 'year') label.textContent = `Năm ${selectedDonutYear}`;
  else label.textContent = `Tháng ${selectedDonutMonth}/${selectedDonutYear}`;
}

function stepDonutPeriod(direction) {
  if (currentDonutTime === 'month') {
    selectedDonutMonth += direction;
    if (selectedDonutMonth > 12) { selectedDonutMonth = 1; selectedDonutYear += 1; }
    else if (selectedDonutMonth < 1) { selectedDonutMonth = 12; selectedDonutYear -= 1; }
  } else if (currentDonutTime === 'year') {
    selectedDonutYear += direction;
  }
  updateDonutPeriodUI();
  drawCategoryDonutChart('categoryDonutCanvasFull', 360, 360, false);
}

function populateYearSelectOptions() {
  const yearSelect = document.getElementById('chartYearSelect');
  if (!yearSelect) return;

  const yearsSet = new Set([2026, 2025, 2024]);
  transactions.forEach(e => {
    if (e.date) {
      const y = parseInt(e.date.split('-')[0], 10);
      if (!isNaN(y)) yearsSet.add(y);
    }
  });

  yearSelect.innerHTML = '';
  Array.from(yearsSet).sort((a, b) => b - a).forEach(y => {
    const opt = document.createElement('option');
    opt.value = y;
    opt.textContent = `Năm ${y}`;
    if (y === selectedBarYear) opt.selected = true;
    yearSelect.appendChild(opt);
  });
}

// A. DONUT / PIE CHART ON CANVAS (WITH SWIPE & DRAG SUPPORT)
function drawCategoryDonutChart(canvasId, width, height, isMini) {
  const canvas = document.getElementById(canvasId);
  if (!canvas) return;
  const ctx = canvas.getContext('2d');
  ctx.clearRect(0, 0, width, height);

  let targetExpenses = transactions.filter(t => t.type === 'expense');
  let centerTitle = 'Tổng Chi';

  if (!isMini) {
    if (currentDonutTime === 'month') {
      const targetMonthPrefix = `${selectedDonutYear}-${String(selectedDonutMonth).padStart(2, '0')}`;
      targetExpenses = targetExpenses.filter(e => e.date && e.date.startsWith(targetMonthPrefix));
      centerTitle = `T${selectedDonutMonth}/${selectedDonutYear}`;
    } else if (currentDonutTime === 'year') {
      const targetYearPrefix = `${selectedDonutYear}`;
      targetExpenses = targetExpenses.filter(e => e.date && e.date.startsWith(targetYearPrefix));
      centerTitle = `Năm ${selectedDonutYear}`;
    } else {
      centerTitle = 'Toàn Bộ';
    }
  }

  const totals = {};
  let grandTotal = 0;
  Object.keys(CATEGORIES).forEach(k => totals[k] = 0);

  targetExpenses.forEach(e => {
    const cat = e.category in CATEGORIES ? e.category : 'other';
    totals[cat] = (totals[cat] || 0) + (Number(e.amount) || 0);
    grandTotal += Number(e.amount) || 0;
  });

  const center = { x: width / 2, y: height / 2 };
  const radius = Math.min(width, height) / 2 - 16;
  const innerRadius = radius * 0.65;

  if (grandTotal === 0) {
    ctx.strokeStyle = document.body.getAttribute('data-theme') === 'dark' ? '#24304f' : '#e2e8f0';
    ctx.lineWidth = 14;
    ctx.beginPath();
    ctx.arc(center.x, center.y, radius - 7, 0, Math.PI * 2);
    ctx.stroke();

    ctx.fillStyle = document.body.getAttribute('data-theme') === 'dark' ? '#94a3b8' : '#64748b';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.font = 'bold 12px Plus Jakarta Sans, sans-serif';
    ctx.fillText(centerTitle, center.x, center.y - 10);
    ctx.font = '11px Plus Jakarta Sans, sans-serif';
    ctx.fillText('0 đ (Chưa có dữ liệu)', center.x, center.y + 10);

    if (!isMini) {
      const legend = document.getElementById('donutLegendContainer');
      if (legend) legend.innerHTML = '<div style="color:var(--text-muted); font-size:12px;">Không có chi tiêu trong kỳ này</div>';
    }
    return;
  }

  let startAngle = -Math.PI / 2;

  Object.entries(totals).forEach(([catKey, val]) => {
    if (val <= 0) return;
    const sliceAngle = (val / grandTotal) * Math.PI * 2;
    const endAngle = startAngle + sliceAngle;

    ctx.beginPath();
    ctx.arc(center.x, center.y, radius, startAngle, endAngle - 0.02);
    ctx.arc(center.x, center.y, innerRadius, endAngle - 0.02, startAngle, true);
    ctx.closePath();
    ctx.fillStyle = CATEGORIES[catKey]?.color || '#475569';
    ctx.fill();

    startAngle = endAngle;
  });

  // Center hole text
  ctx.fillStyle = document.body.getAttribute('data-theme') === 'dark' ? '#f8fafc' : '#0f172a';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.font = 'bold 12px Plus Jakarta Sans, sans-serif';
  ctx.fillText(centerTitle, center.x, center.y - 10);
  ctx.font = 'bold 14px Plus Jakarta Sans, sans-serif';
  ctx.fillStyle = '#2563eb';
  ctx.fillText(formatVND(grandTotal), center.x, center.y + 12);

  if (!isMini) {
    const legend = document.getElementById('donutLegendContainer');
    if (legend) {
      legend.innerHTML = '';
      Object.entries(totals).forEach(([catKey, val]) => {
        if (val <= 0) return;
        const percent = ((val / grandTotal) * 100).toFixed(1);
        const cat = CATEGORIES[catKey] || { name: catKey, color: '#475569' };
        const item = document.createElement('div');
        item.className = 'legend-item';
        item.innerHTML = `
          <span class="legend-dot" style="background:${cat.color}"></span>
          <span>${cat.name}: ${percent}% (${formatVND(val)})</span>
        `;
        legend.appendChild(item);
      });
    }
  }
}

// B. FLEXIBLE BAR CHART (WEEK / MONTH / YEAR)
function drawWeeklyBarChart(canvasId, width, height, showValues, modeOverride) {
  const canvas = document.getElementById(canvasId);
  if (!canvas) return;
  const ctx = canvas.getContext('2d');
  ctx.clearRect(0, 0, width, height);

  const mode = modeOverride || currentBarMode;
  let items = [];
  const now = new Date();
  const currentActualYear = now.getFullYear();
  const subtitle = document.getElementById('chartTimeSubtitle');

  if (mode === 'month') {
    const targetYear = selectedBarYear;
    if (subtitle) subtitle.textContent = `Chi tiết 12 tháng của Năm ${targetYear}`;

    for (let m = 1; m <= 12; m++) {
      const monthPrefix = `${targetYear}-${String(m).padStart(2, '0')}`;
      const isCurrentMonth = (targetYear === currentActualYear && m === (now.getMonth() + 1));
      items.push({ key: monthPrefix, label: `T${m}`, amount: 0, isHighlight: isCurrentMonth });
    }

    transactions.forEach(e => {
      if (e.type === 'expense' && e.date && e.date.startsWith(`${targetYear}-`)) {
        const mPart = parseInt(e.date.split('-')[1], 10);
        if (mPart >= 1 && mPart <= 12) items[mPart - 1].amount += Number(e.amount) || 0;
      }
    });
  } else if (mode === 'year') {
    let startYear = currentActualYear - (selectedYearRangeLimit - 1);
    if (selectedYearRangeLimit === 'all') {
      const allYears = transactions.map(e => e.date ? parseInt(e.date.split('-')[0], 10) : currentActualYear).filter(y => !isNaN(y));
      startYear = allYears.length > 0 ? Math.min(...allYears) : currentActualYear - 4;
    }
    if (subtitle) subtitle.textContent = `Thống kê chi tiêu từ năm ${startYear} đến năm ${currentActualYear}`;

    for (let y = startYear; y <= currentActualYear; y++) {
      items.push({ key: `${y}`, label: `${y}`, amount: 0, isHighlight: y === currentActualYear });
    }

    transactions.forEach(e => {
      if (e.type === 'expense' && e.date) {
        const yPart = parseInt(e.date.split('-')[0], 10);
        const match = items.find(it => it.key === `${yPart}`);
        if (match) match.amount += Number(e.amount) || 0;
      }
    });
  } else {
    if (subtitle) subtitle.textContent = `Hiển thị dữ liệu 7 ngày gần nhất`;
    const dayNames = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    for (let i = 6; i >= 0; i--) {
      const d = new Date();
      d.setDate(now.getDate() - i);
      const dateStr = d.toISOString().split('T')[0];
      const isToday = i === 0;
      items.push({ key: dateStr, label: isToday ? 'H.nay' : dayNames[d.getDay()], amount: 0, isHighlight: isToday });
    }

    transactions.forEach(e => {
      if (e.type === 'expense') {
        const match = items.find(d => d.key === e.date);
        if (match) match.amount += Number(e.amount) || 0;
      }
    });
  }

  const maxVal = Math.max(...items.map(d => d.amount), 100000);
  const bottomPadding = 32;
  const topPadding = 24;
  const chartHeight = height - bottomPadding - topPadding;
  const barSpacing = width / items.length;
  const barWidth = Math.min(32, barSpacing * (mode === 'month' ? 0.65 : 0.55));
  const isDark = document.body.getAttribute('data-theme') === 'dark';

  // Grid lines
  ctx.strokeStyle = isDark ? '#24304f' : '#e2e8f0';
  ctx.lineWidth = 1;
  for (let i = 0; i <= 2; i++) {
    const y = topPadding + chartHeight * (1 - i / 2);
    ctx.beginPath();
    ctx.moveTo(10, y);
    ctx.lineTo(width - 10, y);
    ctx.stroke();
  }

  items.forEach((item, index) => {
    const x = index * barSpacing + barSpacing / 2;
    const ratio = Math.min(1, item.amount / maxVal);
    const barHeight = Math.max(4, chartHeight * ratio);
    const y = topPadding + chartHeight - barHeight;

    const grad = ctx.createLinearGradient(0, y, 0, y + barHeight);
    if (item.isHighlight) {
      grad.addColorStop(0, '#2563eb');
      grad.addColorStop(1, '#60a5fa');
    } else {
      grad.addColorStop(0, isDark ? '#3b82f6' : '#93c5fd');
      grad.addColorStop(1, isDark ? '#1e293b' : '#dbeafe');
    }

    ctx.fillStyle = grad;
    drawRoundedRect(ctx, x - barWidth / 2, y, barWidth, barHeight, 5);
    ctx.fill();

    if (item.amount > 0 && showValues) {
      ctx.fillStyle = item.isHighlight ? '#2563eb' : (isDark ? '#94a3b8' : '#64748b');
      ctx.font = 'bold 9px Plus Jakarta Sans, sans-serif';
      ctx.textAlign = 'center';
      const label = item.amount >= 1000000 ? (item.amount / 1000000).toFixed(1) + 'M' : (item.amount / 1000).toFixed(0) + 'k';
      ctx.fillText(label, x, y - 4);
    }

    ctx.fillStyle = item.isHighlight ? '#2563eb' : (isDark ? '#94a3b8' : '#64748b');
    ctx.font = item.isHighlight ? 'bold 11px Plus Jakarta Sans' : '10px Plus Jakarta Sans';
    ctx.textAlign = 'center';
    ctx.fillText(item.label, x, height - 10);
  });
}

function drawRoundedRect(ctx, x, y, width, height, radius) {
  ctx.beginPath();
  ctx.moveTo(x + radius, y);
  ctx.lineTo(x + width - radius, y);
  ctx.quadraticCurveTo(x + width, y, x + width, y + radius);
  ctx.lineTo(x + width, y + height);
  ctx.lineTo(x, y + height);
  ctx.lineTo(x, y + radius);
  ctx.quadraticCurveTo(x, y, x + radius, y);
  ctx.closePath();
}

function renderCategoryBreakdownList() {
  const container = document.getElementById('categoryBreakdownList');
  if (!container) return;
  container.innerHTML = '';

  const totals = {};
  let grandTotal = 0;
  Object.keys(CATEGORIES).forEach(k => totals[k] = 0);
  transactions.filter(t => t.type === 'expense').forEach(e => {
    const cat = e.category in CATEGORIES ? e.category : 'other';
    totals[cat] = (totals[cat] || 0) + (Number(e.amount) || 0);
    grandTotal += Number(e.amount) || 0;
  });

  Object.entries(totals).forEach(([k, val]) => {
    const percent = grandTotal > 0 ? ((val / grandTotal) * 100).toFixed(1) : 0;
    const cat = findCategory(k);
    const bg = hexToLightBg(cat.color);
    const row = document.createElement('div');
    row.className = 'breakdown-row';
    row.innerHTML = `
      <div class="breakdown-left">
        <div class="category-icon-circle" style="background:${bg}; color:${cat.color}; width:36px; height:36px; font-size:16px;">
          <i class="fa-solid ${cat.icon}"></i>
        </div>
        <div>
          <div class="breakdown-cat-name">${escapeHtml(cat.name)}</div>
          <div style="font-size:12px; color:var(--text-muted);">${percent}% trên tổng chi</div>
        </div>
      </div>
      <div class="breakdown-amount" style="color:${cat.color};">${formatVND(val)}</div>
    `;
    container.appendChild(row);
  });
}

// --- 12. OCR RECEIPT & BANK TRANSFER PARSER ---
const PRESET_RECEIPTS = {
  // A. Bank & E-Wallet Transfers
  vcb_rent: `VIETCOMBANK - VCB DIGIBANK
GIAO DICH CHUYEN TIEN THANH CONG
So tien: 2.500.000 VND
Ten nguoi thu huong: TRAN THI BINH
Ngan hang thu huong: MB Bank
Ngay giao dich: 08/10/2026 09:15:20
Noi dung: Chuyen tien thue phong tro thang 10/2026
Ma giao dich: VCB9837482910`,

  tcb_salary: `TECHCOMBANK MOBILE
BIEN DONG SO DU (+ TIEN VAO)
So tien: +15.000.000 VND
Nguoi gui: CONG TY TNHH CONG NGHE NEXTGEN
Tai khoan nguon: 1903482918293
Ngay: 05/10/2026 17:00
Noi dung: Thanh toan luong thang 09/2026 va thuong KPI du an
Ma GD: TCB847291038`,

  mbbank_food: `MB BANK - GIAO DICH THANH CONG
Chuyen tien nhanh 247 Napas
So tien chuyen: 250.000 VND
Nguoi nhan: LE HOANG NAM
Ngay tao: 07/10/2026 12:45
Loi nhan: Tien an trua lien hoan pizza nhom do an
Trang thai: Thanh cong`,

  tpbank_edu: `TPBANK MOBILE
CHUYEN KHOAN THANH CONG
So tien: 1.200.000 VND
Don vi thu huong: TRUNG TAM ANH NGU & LAP TRINH
Ngay thuc hien: 06/10/2026 14:10
Noi dung: Hoc phi khoa hoc Flutter AI thang 10
Ma tham chieu: TPB49201948`,

  momo_bill: `VI MOMO - THANH TOAN THANH CONG
Dich vu: HOA DON TIEN DIEN EVN
So tien thanh toan: 450.000 d
Khach hang: EVN HO CHI MINH - PE0800019283
Thoi gian: 04/10/2026 20:30
Noi dung: Thanh toan tien dien sinh hoat ky 09/2026`,

  // B. Retail Invoices & Bills
  winmart: `SIEU THI WINMART+ VINCOM
Dia chi: 123 Nguyen Trai, Q.1, TP.HCM
Ngay: 08/10/2026 10:15
--------------------------------
1. Sua tuoi Vinamilk 1L    32.000
2. Banh mi sandwich        25.000
3. Tao My Envy (1kg)       95.000
4. Nuoc khoang Lavie 500ml 10.000
--------------------------------
TONG CONG: 162.000 VND
Thanh toan: 162.000 d`,

  highlands: `HIGHLANDS COFFEE
Chi nhanh: Landmark 81, Binh Thanh
Ngay HD: 07/10/2026 15:30
-----------------------------
1. Freeze Tra Xanh (L)     69.000
2. Phin Sua Da (M)         39.000
3. Banh Mousse Pho Mai     45.000
-----------------------------
TONG CONG: 153.000 d
THANH TOAN TIEN MAT: 153.000 VND`,

  fahasa: `NHA SACH FAHASA NGUYEN HUE
D/C: 40 Nguyen Hue, Quan 1, TP.HCM
Ngay GD: 06/10/2026 18:45
-----------------------------
1. Giao trinh Lap Trinh Dart 145.000
2. So tay A5 Dot Grid         65.000
3. But gel Pilot G2-0.5       30.000
-----------------------------
CONG TIEN HANG: 240.000 d
TONG THANH TOAN: 240.000 VND`,

  grab: `GRAB VIETNAM
BIEN LAI DIEN TU - GRABBIKE
Ngay: 05/10/2026 08:20
-----------------------------
Chuyen di tu Quan 3 den Dai Hoc BK
Gia cuoc chuyen di: 38.000 VND
Khuyen mai GrabPay: -5.000 VND
-----------------------------
TONG THANH TOAN: 33.000 d`,

  cgv: `CGV CINEMAS VINCOM
Rap: CGV Dong Khoi - Cinema 03
Ngay chieu: 04/10/2026 19:30
-----------------------------
1. Ve xem phim 2D Standard   100.000
2. Bap rang bo Ngot (M)       30.000
-----------------------------
TONG TIEN: 130.000 VND
Thanh toan the: 130.000 d`,

  tgdd: `THE GIOI DI DONG
Sieu thi: 234 CMT8, Quan 3
Ngay mua: 03/10/2026 11:00
-----------------------------
1. Chuot khong day Logitech M330 350.000
Bao hanh 12 thang chinh hang
-----------------------------
TONG TIEN THANH TOAN: 350.000 VND`,

  petrolimex: `PETROLIMEX CUA HANG XANG DAU SO 12
Dia chi: Dien Bien Phu, Binh Thanh
Ngay: 02/10/2026 07:45
-----------------------------
Xang RON 95-III (3.85 lit)
Don gia: 23.370 d/lit
-----------------------------
TONG TIEN: 90.000 VND
Thanh toan QR Code: 90.000 d`
};

let reviewModalType = 'expense';

class ReceiptParser {
  // Detect transaction type (income vs expense)
  static extractType(raw) {
    const lower = raw.toLowerCase();
    if (/\+\s*[\d\.,]+|\bbi[eế]n\s*đ[oộ]ng\s*s[oố]\s*d[uư]\s*\(\+|\bti[eề]n\s*v[aà]o\b|\bnh[aậ]n\s*ti[eề]n\s*t[uừ]\b|\bl[uư][oơ]ng\b|\bth[uù]\s*lao\b|\bth[uư][oở]ng\b/i.test(lower)) {
      return 'income';
    }
    return 'expense';
  }

  // Extract total amount with priority heuristic regex
  static extractTotal(raw) {
    const lines = raw.split('\n');
    const kw = /(s[oố]\s*ti[eề]n\s*chuy[eể]n|s[oố]\s*ti[eề]n\s*thanh\s*to[aá]n|s[oố]\s*ti[eề]n|t[oổ]ng\s*ti[eề]n|t[oổ]ng\s*c[oộ]ng|t[oổ]ng\s*thanh\s*to[aá]n|thanh\s*to[aá]n|c[oộ]ng\s*ti[eề]n\s*h[aà]ng|total\s*amount|total|grand\s*total|c[oộ]ng|ti[eề]n\s*m[aặ]t)/i;
    const numP = /[\d]{1,3}(?:[.,]\d{3})*(?:[.,]\d{1,2})?|\d{4,9}/g;

    let candidateTotals = [];

    for (const line of lines) {
      if (kw.test(line)) {
        const matches = line.match(numP);
        if (matches && matches.length > 0) {
          const val = this._cleanNumber(matches[matches.length - 1]);
          if (val && val >= 1000) {
            candidateTotals.push(val);
          }
        }
      }
    }

    if (candidateTotals.length > 0) {
      return candidateTotals[candidateTotals.length - 1];
    }

    // Fallback: search lines ending with VND or d
    for (let i = lines.length - 1; i >= 0; i--) {
      const line = lines[i];
      if (/(vnd|vnđ|d|đ)/i.test(line)) {
        const matches = line.match(numP);
        if (matches && matches.length > 0) {
          const val = this._cleanNumber(matches[matches.length - 1]);
          if (val && val >= 1000) return val;
        }
      }
    }

    return 150000;
  }

  // Extract transaction date and format as YYYY-MM-DD
  static extractDate(raw) {
    // 1. DD/MM/YYYY or DD-MM-YYYY or DD.MM.YYYY
    const dmyPattern = /\b(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{4})\b/;
    const dmyMatch = raw.match(dmyPattern);
    if (dmyMatch) {
      const day = dmyMatch[1].padStart(2, '0');
      const month = dmyMatch[2].padStart(2, '0');
      const year = dmyMatch[3];
      return `${year}-${month}-${day}`;
    }

    // 2. YYYY/MM/DD or YYYY-MM-DD
    const ymdPattern = /\b(\d{4})[\/\-\.](\d{1,2})[\/\-\.](\d{1,2})\b/;
    const ymdMatch = raw.match(ymdPattern);
    if (ymdMatch) {
      const year = ymdMatch[1];
      const month = ymdMatch[2].padStart(2, '0');
      const day = ymdMatch[3].padStart(2, '0');
      return `${year}-${month}-${day}`;
    }

    // 3. "Ngay DD thang MM nam YYYY"
    const vnDatePattern = /ng[aà]y\s*(\d{1,2})\s*th[aá]ng\s*(\d{1,2})\s*n[aă]m\s*(\d{4})/i;
    const vnMatch = raw.match(vnDatePattern);
    if (vnMatch) {
      return `${vnMatch[3]}-${vnMatch[2].padStart(2, '0')}-${vnMatch[1].padStart(2, '0')}`;
    }

    // Default to current date
    return new Date().toISOString().split('T')[0];
  }

  // Extract merchant, beneficiary or sender name
  static extractMerchant(raw) {
    const lines = raw.split('\n').map(l => l.trim());

    // 1. Check Bank Beneficiary / Recipient / Sender patterns
    const recipientPatterns = [
      /(?:t[eê]n\s*ng[uư][oờ]i\s*th[uụ]\s*h[uư][oở]ng|ng[uư][oờ]i\s*th[uụ]\s*h[uư][oở]ng|[đd][oơ]?n\s*v[iị]?\s*th[uụ]?\s*h[uư][oở]?ng|t[eê]n\s*ng[uư][oờ]i\s*nh[aậ]n|ng[uư][oờ]i\s*nh[aậ]n|t[aà]i\s*kho[aả]n\s*nh[aậ]n|kh[aá]ch\s*h[aà]ng|ng[uư][oờ]i\s*g[uử]i):\s*(.+)/i,
      /(?:đ[eế]n\s*t[aà]i\s*kho[aả]n|chuy[eể]n\s*đ[eế]n):\s*(.+)/i
    ];

    for (const line of lines) {
      for (const p of recipientPatterns) {
        const match = line.match(p);
        if (match && match[1]) {
          let name = match[1].replace(/[\(\[].*?[\)\]]/g, '').trim();
          if (name.length > 2) return name;
        }
      }
    }

    // 2. Check Retail Brands & Stores
    const lower = raw.toLowerCase();
    if (lower.includes('winmart')) return 'Siêu thị WinMart+';
    if (lower.includes('highlands')) return 'Highlands Coffee';
    if (lower.includes('fahasa')) return 'Nhà sách Fahasa';
    if (lower.includes('grab')) return 'Grab Bike / GrabPay';
    if (lower.includes('cgv')) return 'CGV Cinemas';
    if (lower.includes('the gioi di dong') || lower.includes('tgdd')) return 'Thế Giới Di Động';
    if (lower.includes('petrolimex')) return 'Cửa hàng Xăng dầu Petrolimex';
    if (lower.includes('phuc long')) return 'Phúc Long Coffee & Tea';
    if (lower.includes('starbucks')) return 'Starbucks Coffee';
    if (lower.includes('circle k')) return 'Circle K';
    if (lower.includes('gs25')) return 'Cửa hàng GS25';
    if (lower.includes('ministop')) return 'Ministop';
    if (lower.includes('coopmart') || lower.includes('co.op')) return 'Siêu thị Co.opmart';
    if (lower.includes('fpt shop')) return 'FPT Shop';

    // 3. Check Bank App Headers
    if (lower.includes('vietcombank') || lower.includes('vcb')) return 'Chuyển khoản Vietcombank';
    if (lower.includes('techcombank') || lower.includes('tcb')) return 'Chuyển khoản Techcombank';
    if (lower.includes('mb bank') || lower.includes('mbbank')) return 'Chuyển khoản MB Bank';
    if (lower.includes('tpbank')) return 'Chuyển khoản TPBank';
    if (lower.includes('vpbank')) return 'Chuyển khoản VPBank';
    if (lower.includes('momo')) return 'Ví điện tử MoMo';
    if (lower.includes('zalopay')) return 'Ví ZaloPay';

    // 4. Heuristic: First meaningful non-empty line
    const cleanLines = lines.filter(l => l.length > 0);
    for (const line of cleanLines.slice(0, 3)) {
      if (!/^(h[oó]a\s*đ[oơ]n|phi[eế]u|bi[eê]n\s*lai|receipt|bill|invoice|giao\s*d[iị]ch|chuy[eể]n\s*ti[eề]n)/i.test(line)) {
        return line.replace(/^[\W_]+/, '').trim();
      }
    }

    return 'Giao dịch chuyển khoản / Hóa đơn';
  }

  // Extract Transfer Content (Nội dung chuyển khoản) or Purchased Items List
  static extractNote(raw) {
    const lines = raw.split('\n').map(l => l.trim());

    // 1. Bank transfer note pattern
    const notePattern = /(?:n[oộ]i\s*dung\s*(?:chuy[eể]n\s*ti[eề]n|thanh\s*to[aá]n)?|l[oờ]i\s*nh[aắ]n|ghi\s*ch[uú]|d[iị]ch\s*v[uụ]|chi\s*ti[eế]t):\s*(.+)/i;
    for (const line of lines) {
      const match = line.match(notePattern);
      if (match && match[1]) {
        return match[1].trim();
      }
    }

    // 2. Retail invoice line items
    const items = [];
    const itemNumPattern = /^\d+[\.\)]\s*(.+)/;
    for (const line of lines) {
      const match = line.match(itemNumPattern);
      if (match) {
        const itemText = match[1].replace(/[\d\.,]+\s*(vnd|vnđ|d|đ)?$/i, '').trim();
        if (itemText.length > 2) {
          items.push(itemText);
        }
      }
    }

    if (items.length > 0) {
      return items.join(', ');
    }

    return '';
  }

  // Auto-classify category based on text content, transfer note & merchant
  static classifyCategory(raw, merchant, note) {
    const text = (raw + ' ' + merchant + ' ' + note).toLowerCase();

    // Entertainment / Movies
    if (/cgv|lotte|cinema|v[eé]\s*xem\s*phim|r[aạ]p\s*phim|gi[aả]i\s*tr[ií]|karaoke|game|billiards/i.test(text)) {
      return 'entertainment';
    }
    // Rent / Housing (with strict boundary to avoid matching "tien nhan")
    if (/\b(?:ph[oò]ng\s*tr[oọ]|ti[eề]n\s*nh[aà]|thu[eê]\s*nh[aà]|thu[eê]\s*ph[oò]ng|c[aă]n\s*h[oộ]|chung\s*c[uư]|rent)\b/i.test(text)) {
      return 'rent';
    }
    // Salary & Income
    if (/l[uư][oơ]ng|th[uù]\s*lao|th[uư][oở]ng|kpi|salary/i.test(text)) {
      return 'salary';
    }
    // Education
    if (/s[aá]ch|fahasa|gi[aá]o\s*tr[iì]nh|v[oở]|b[uú]t|h[oọ]c\s*ph[ií]|kh[oó]a\s*h[oọ]c|bullet|pilot|b[aà]i\s*t[aậ]p|anh\s*ng[uữ]|l[aậ]p\s*tr[iì]nh/i.test(text)) {
      return 'education';
    }
    // Food & Dining
    if (/coffee|c[aà]\s*ph[eê]|tr[aà]|freeze|mousse|b[aá]nh|ph[oở]|b[uú]n|c[oơ]m|l[aả]u|g[aà]\s*r[aá]n|pizza|highlands|phuc long|starbucks|an uong|[aă]n\s*tr[uư]a|li[eê]n\s*hoan|n[uư][oớ]c\s*[eé]p|sinh\s*t[oố]/i.test(text)) {
      return 'food';
    }
    // Utilities
    if (/ti[eề]n\s*đi[eệ]n|evn|ti[eề]n\s*n[uư][oớ]c|wifi|viettel|vnpt|fpt\s*telecom|đi[eệ]n\s*sinh\s*ho[aạ]t/i.test(text)) {
      return 'utility';
    }
    // Transport & Gas
    if (/grab|be|gojek|x[aă]ng|petrolimex|g[uử]i\s*xe|v[eé]\s*xe|xe\s*bu[yý]t|taxi|mai\s*linh/i.test(text)) {
      return 'transport';
    }
    // Devices & Tech
    if (/chu[oộ]t|b[aà]n\s*ph[ií]m|laptop|tai\s*nghe|pin|tgdd|th[eế]\s*gi[oớ]i\s*di\s*đ[oộ]ng|fpt|cellphone|c[oô]ng\s*ngh[eệ]/i.test(text)) {
      return 'devices';
    }
    // Clothes & Fashion
    if (/qu[aầ]n|[aá]o|gi[aà]y|d[eé]p|t[uú]i|zara|uniqlo|canifa|th[oờ]i\s*trang/i.test(text)) {
      return 'clothes';
    }
    // Daily Groceries
    if (/winmart|circle\s*k|gs25|family\s*mart|coop|b[aá]ch\s*h[oó]a|s[uữ]a|si[eê]u\s*th[iị]|lavie|sandwich/i.test(text)) {
      return 'daily';
    }
    // Investment
    if (/ti[eế]t\s*ki[eệ]m|ch[uứ]ng\s*kho[aá]n|đ[aầ]u\s*t[uư]|invest/i.test(text)) {
      return 'invest';
    }

    // Check matching custom category names
    for (const [catId, cat] of Object.entries(CATEGORIES)) {
      if (text.includes(cat.name.toLowerCase())) {
        return catId;
      }
    }

    return 'other';
  }

  static _cleanNumber(str) {
    return parseFloat(str.replace(/\./g, '').replace(/,/g, '').replace(/[^\d]/g, '')) || 0;
  }

  static parse(raw) {
    const type = this.extractType(raw);
    const amount = this.extractTotal(raw);
    const date = this.extractDate(raw);
    const merchant = this.extractMerchant(raw);
    const note = this.extractNote(raw);
    const category = this.classifyCategory(raw, merchant, note);

    return { type, merchant, amount, date, category, note, rawText: raw };
  }
}

function processRawOcrText(raw) {
  const p = ReceiptParser.parse(raw);
  closeModal('scanModal');

  // Set Type (Income vs Expense)
  reviewModalType = p.type || 'expense';
  const expBtn = document.getElementById('reviewTypeExpense');
  const incBtn = document.getElementById('reviewTypeIncome');
  if (expBtn && incBtn) {
    if (reviewModalType === 'income') {
      incBtn.classList.add('active');
      expBtn.classList.remove('active');
    } else {
      expBtn.classList.add('active');
      incBtn.classList.remove('active');
    }
  }

  // Auto-populate all extracted information
  document.getElementById('reviewMerchant').value = p.merchant;
  document.getElementById('reviewAmount').value = p.amount;
  document.getElementById('reviewDate').value = p.date;
  document.getElementById('reviewNote').value = p.note || '';
  document.getElementById('reviewRawOcrText').textContent = p.rawText;

  // Auto-select category radio
  renderCategoryRadioGroup('reviewCategoryGroup', 'reviewCategory', p.category, reviewModalType);

  // Open review & verification modal
  openModal('reviewModal');
}

// Client-Side OCR with Tesseract
async function performClientOCR(imageSrc) {
  const loading = document.getElementById('ocrLoading');
  loading.classList.remove('hidden');

  try {
    if (typeof Tesseract !== 'undefined') {
      const worker = await Tesseract.createWorker('vie+eng');
      const ret = await worker.recognize(imageSrc);
      await worker.terminate();
      loading.classList.add('hidden');
      processRawOcrText(ret.data.text);
    } else {
      loading.classList.add('hidden');
      processRawOcrText(PRESET_RECEIPTS.winmart);
    }
  } catch (err) {
    loading.classList.add('hidden');
    processRawOcrText(PRESET_RECEIPTS.winmart);
  }
}

// --- 13. MODAL HELPERS ---
function openModal(id) {
  document.getElementById(id).classList.add('active');
  if (id === 'scanModal') startWebcam();
}

function closeModal(id) {
  document.getElementById(id).classList.remove('active');
  if (id === 'scanModal') stopWebcam();
}

async function startWebcam() {
  const v = document.getElementById('webcamVideo');
  try {
    webcamStream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' } });
    v.srcObject = webcamStream;
  } catch (_) {}
}

function stopWebcam() {
  if (webcamStream) {
    webcamStream.getTracks().forEach(t => t.stop());
    webcamStream = null;
  }
}

function openEditModal(item) {
  document.getElementById('addEditTitle').innerHTML = '<i class="fa-solid fa-pen-to-square"></i> Chỉnh Sửa Giao Dịch';
  document.getElementById('editExpenseId').value = item.id;
  document.getElementById('manualMerchant').value = item.merchant;
  document.getElementById('manualAmount').value = item.amount;
  document.getElementById('manualDate').value = item.date;
  document.getElementById('manualNote').value = item.note || '';

  manualModalType = item.type || 'expense';
  if (manualModalType === 'income') {
    document.getElementById('modalTypeIncome').classList.add('active');
    document.getElementById('modalTypeExpense').classList.remove('active');
  } else {
    document.getElementById('modalTypeExpense').classList.add('active');
    document.getElementById('modalTypeIncome').classList.remove('active');
  }

  renderCategoryRadioGroup('manualCategoryGroup', 'manualCategory', item.category, manualModalType);
  openModal('addEditModal');
}

// --- 14. INITIALIZATION & EVENT LISTENERS ---
document.addEventListener('DOMContentLoaded', () => {
  loadState();
  updateUI();

  // Tab switching
  document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
      document.querySelectorAll('.tab-pane').forEach(p => p.classList.remove('active'));

      btn.classList.add('active');
      const target = document.getElementById(`tab-${btn.dataset.tab}`);
      if (target) target.classList.add('active');

      updateUI();
    });
  });

  // Theme Toggle
  document.getElementById('themeToggleBtn').addEventListener('click', () => {
    const isDark = document.body.getAttribute('data-theme') === 'dark';
    document.body.setAttribute('data-theme', isDark ? 'light' : 'dark');
    document.getElementById('themeToggleBtn').innerHTML = isDark ? '<i class="fa-solid fa-moon"></i>' : '<i class="fa-solid fa-sun"></i>';
    updateUI();
  });

  // Top Action Buttons
  document.getElementById('openScanBtn').addEventListener('click', () => openModal('scanModal'));
  document.getElementById('dashScanBtn').addEventListener('click', () => openModal('scanModal'));
  document.getElementById('openBudgetBtn').addEventListener('click', () => {
    populateMasterBudgetModal();
  });
  document.getElementById('editMasterBudgetBtn')?.addEventListener('click', () => {
    populateMasterBudgetModal();
  });
  document.getElementById('addCategoryBudgetBtn')?.addEventListener('click', () => {
    openCategoryBudgetModal();
  });
  document.getElementById('viewAllTransBtn').addEventListener('click', () => {
    document.querySelector('.tab-btn[data-tab="transactions"]').click();
  });

  // Category Manager Modal Open
  document.getElementById('openCategoryManagerBtn').addEventListener('click', () => {
    renderCategoryManagerList(currentCatFilter);
    openModal('categoryManagerModal');
  });

  // Category Filter Tabs in Category Manager
  document.querySelectorAll('.cat-type-tab').forEach(tab => {
    tab.addEventListener('click', () => {
      document.querySelectorAll('.cat-type-tab').forEach(t => t.classList.remove('active'));
      tab.classList.add('active');
      currentCatFilter = tab.dataset.catFilter;
      renderCategoryManagerList(currentCatFilter);
    });
  });

  // Add Category Button in Manager
  document.getElementById('addNewCategoryBtn').addEventListener('click', () => {
    openAddCategoryModal();
  });

  // Category Name Input live preview
  document.getElementById('categoryNameInput').addEventListener('input', () => {
    updateCategoryLivePreview();
  });

  // Category Type Selection in Add/Edit
  document.getElementById('catTypeExpense').addEventListener('click', () => {
    selectedCategoryType = 'expense';
    document.getElementById('catTypeExpense').classList.add('active');
    document.getElementById('catTypeIncome').classList.remove('active');
    document.getElementById('catTypeBoth').classList.remove('active');
  });
  document.getElementById('catTypeIncome').addEventListener('click', () => {
    selectedCategoryType = 'income';
    document.getElementById('catTypeIncome').classList.add('active');
    document.getElementById('catTypeExpense').classList.remove('active');
    document.getElementById('catTypeBoth').classList.remove('active');
  });
  document.getElementById('catTypeBoth').addEventListener('click', () => {
    selectedCategoryType = 'both';
    document.getElementById('catTypeBoth').classList.add('active');
    document.getElementById('catTypeExpense').classList.remove('active');
    document.getElementById('catTypeIncome').classList.remove('active');
  });

  // Add/Edit Category Form Submit
  document.getElementById('addEditCategoryForm').addEventListener('submit', (e) => {
    e.preventDefault();
    const name = document.getElementById('categoryNameInput').value.trim();
    if (!name) return;

    let catId = document.getElementById('editCategoryId').value;
    if (!catId) {
      // Generate new slug or ID
      const baseSlug = name.toLowerCase().replace(/[^a-z0-9]/g, '_') || 'cat';
      catId = baseSlug + '_' + Date.now().toString().slice(-4);
    }

    CATEGORIES[catId] = {
      name: name,
      icon: selectedCategoryIcon,
      color: selectedCategoryColor,
      bg: hexToLightBg(selectedCategoryColor),
      type: selectedCategoryType
    };

    saveCategories();
    closeModal('addEditCategoryModal');
    renderCategoryManagerList(currentCatFilter);
    renderCategoryChips();
    updateUI();
  });

  // Category Budget Form Submit with Strict Check
  document.getElementById('categoryBudgetForm').addEventListener('submit', (e) => {
    e.preventDefault();
    let catId = document.getElementById('catBudgetId').value;
    if (!catId) {
      catId = document.getElementById('catBudgetSelect').value;
    }
    const amount = parseFloat(document.getElementById('catBudgetAmountInput').value) || 0;

    const otherSum = getTotalCategoryBudgets(catId);
    const maxAvailable = Math.max(0, monthlyBudget - otherSum);

    if (amount > maxAvailable) {
      alert(`Không thể lưu: Hạn mức (${formatVND(amount)}) làm tổng các hạn mức vượt quá Tổng ngân sách tháng (${formatVND(monthlyBudget)}).\nTối đa có thể đặt cho danh mục này là ${formatVND(maxAvailable)}.`);
      return;
    }

    if (catId && amount > 0) {
      categoryBudgets[catId] = amount;
      saveState();
      closeModal('categoryBudgetModal');
      updateUI();
    }
  });

  // Real-time input validation on Category Budget modal
  document.getElementById('catBudgetAmountInput').addEventListener('input', () => {
    let catId = document.getElementById('catBudgetId').value;
    if (!catId) {
      catId = document.getElementById('catBudgetSelect').value;
    }
    const otherSum = getTotalCategoryBudgets(catId);
    const maxAvailable = Math.max(0, monthlyBudget - otherSum);
    validateCategoryBudgetInput(maxAvailable);
  });

  // Preset Set Max Button click
  document.getElementById('presetSetMaxBtn')?.addEventListener('click', () => {
    let catId = document.getElementById('catBudgetId').value;
    if (!catId) {
      catId = document.getElementById('catBudgetSelect').value;
    }
    const otherSum = getTotalCategoryBudgets(catId);
    const maxAvailable = Math.max(0, monthlyBudget - otherSum);
    document.getElementById('catBudgetAmountInput').value = maxAvailable;
    validateCategoryBudgetInput(maxAvailable);
  });

  // Remove Category Budget Button
  document.getElementById('removeCatBudgetBtn').addEventListener('click', () => {
    const catId = document.getElementById('catBudgetId').value;
    if (catId && categoryBudgets[catId]) {
      const cat = findCategory(catId);
      if (confirm(`Bạn có chắc muốn xóa hạn mức của danh mục "${cat.name}"?`)) {
        delete categoryBudgets[catId];
        saveState();
        closeModal('categoryBudgetModal');
        updateUI();
      }
    }
  });

  // Quick Preset Buttons for Category Budget
  document.querySelectorAll('[data-cat-preset]').forEach(btn => {
    btn.addEventListener('click', () => {
      const delta = parseInt(btn.dataset.catPreset, 10) || 0;
      const input = document.getElementById('catBudgetAmountInput');
      const current = parseFloat(input.value) || 0;

      let catId = document.getElementById('catBudgetId').value;
      if (!catId) {
        catId = document.getElementById('catBudgetSelect').value;
      }
      const otherSum = getTotalCategoryBudgets(catId);
      const maxAvailable = Math.max(0, monthlyBudget - otherSum);

      const targetVal = Math.min(maxAvailable, current + delta);
      input.value = targetVal;
      validateCategoryBudgetInput(maxAvailable);
    });
  });

  // Category selection change in budget modal
  document.getElementById('catBudgetSelect')?.addEventListener('change', (e) => {
    const selected = e.target.value;
    if (selected) {
      updateCategoryBudgetLimitGuidance(selected);
      if (categoryBudgets[selected]) {
        document.getElementById('catBudgetAmountInput').value = categoryBudgets[selected];
      } else {
        document.getElementById('catBudgetAmountInput').value = '';
      }
      const otherSum = getTotalCategoryBudgets(selected);
      const maxAvailable = Math.max(0, monthlyBudget - otherSum);
      validateCategoryBudgetInput(maxAvailable);
    }
  });

  // Master Budget Form Submit (with inline category budgets & strict validation)
  document.getElementById('budgetForm').addEventListener('submit', (e) => {
    e.preventDefault();
    const masterVal = parseFloat(document.getElementById('monthlyBudgetInput').value) || 0;

    let allocatedSum = 0;
    const newCatBudgets = {};
    document.querySelectorAll('.modal-cat-limit-input').forEach(input => {
      const catId = input.dataset.catId;
      const limitVal = parseFloat(input.value) || 0;
      if (limitVal > 0) {
        newCatBudgets[catId] = limitVal;
        allocatedSum += limitVal;
      }
    });

    if (allocatedSum > masterVal) {
      alert(`Không thể lưu: Tổng các hạn mức danh mục (${formatVND(allocatedSum)}) đang vượt quá Tổng ngân sách (${formatVND(masterVal)}) là ${formatVND(allocatedSum - masterVal)}!\nVui lòng giảm bớt hạn mức các danh mục hoặc tăng tổng ngân sách.`);
      return;
    }

    if (masterVal > 0) {
      monthlyBudget = masterVal;
      categoryBudgets = newCatBudgets;

      saveState();
      closeModal('budgetModal');
      updateUI();
    }
  });

  // Manual Add Modal
  document.getElementById('openAddBtn').addEventListener('click', () => {
    document.getElementById('addEditTitle').innerHTML = '<i class="fa-solid fa-plus"></i> Thêm Giao Dịch Mới';
    document.getElementById('addEditForm').reset();
    document.getElementById('editExpenseId').value = '';
    document.getElementById('manualDate').value = '2026-10-08';
    manualModalType = 'expense';
    document.getElementById('modalTypeExpense').classList.add('active');
    document.getElementById('modalTypeIncome').classList.remove('active');
    renderCategoryRadioGroup('manualCategoryGroup', 'manualCategory', 'food', 'expense');
    openModal('addEditModal');
  });
  document.getElementById('dashAddBtn').addEventListener('click', () => {
    document.getElementById('openAddBtn').click();
  });

  document.getElementById('modalTypeExpense').addEventListener('click', () => {
    manualModalType = 'expense';
    document.getElementById('modalTypeExpense').classList.add('active');
    document.getElementById('modalTypeIncome').classList.remove('active');
    renderCategoryRadioGroup('manualCategoryGroup', 'manualCategory', 'food', 'expense');
  });

  document.getElementById('modalTypeIncome').addEventListener('click', () => {
    manualModalType = 'income';
    document.getElementById('modalTypeIncome').classList.add('active');
    document.getElementById('modalTypeExpense').classList.remove('active');
    renderCategoryRadioGroup('manualCategoryGroup', 'manualCategory', 'salary', 'income');
  });

  // Close modals
  document.querySelectorAll('[data-close]').forEach(btn => {
    btn.addEventListener('click', () => closeModal(btn.dataset.close));
  });

  // Search & Sort
  document.getElementById('searchInput').addEventListener('input', (e) => {
    currentSearchQuery = e.target.value;
    renderFullTransactionsList();
  });
  document.getElementById('sortSelect').addEventListener('change', (e) => {
    currentSort = e.target.value;
    renderFullTransactionsList();
  });

  // Export CSV & JSON
  document.getElementById('exportCsvBtn').addEventListener('click', () => {
    let csv = '\uFEFFMã GD,Loại,Cửa hàng,Số tiền,Ngày,Danh mục,Ghi chú\n';
    transactions.forEach(t => {
      csv += `"${t.id}","${t.type}","${t.merchant}","${t.amount}","${t.date}","${CATEGORIES[t.category]?.name || t.category}","${t.note || ''}"\n`;
    });
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = `Chi_Tieu_Finance_${new Date().toISOString().split('T')[0]}.csv`;
    a.click();
  });

  document.getElementById('exportJsonBtn').addEventListener('click', () => {
    const dataStr = JSON.stringify({ transactions, monthlyBudget, categoryBudgets, categories: CATEGORIES }, null, 2);
    const blob = new Blob([dataStr], { type: 'application/json' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = `Backup_Finance_${new Date().toISOString().split('T')[0]}.json`;
    a.click();
  });

  // Calendar Controls
  document.getElementById('calPrevMonth').addEventListener('click', () => {
    currentCalMonth -= 1;
    if (currentCalMonth < 1) { currentCalMonth = 12; currentCalYear -= 1; }
    renderCalendarScreen();
  });
  document.getElementById('calNextMonth').addEventListener('click', () => {
    currentCalMonth += 1;
    if (currentCalMonth > 12) { currentCalMonth = 1; currentCalYear += 1; }
    renderCalendarScreen();
  });

  // Analytics Bar Chart Controls
  document.querySelectorAll('#barTimeToggle .time-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('#barTimeToggle .time-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      currentBarMode = btn.dataset.mode;

      const yearBox = document.getElementById('yearSelectContainer');
      const rangeBox = document.getElementById('yearRangeContainer');

      if (currentBarMode === 'month') {
        populateYearSelectOptions();
        yearBox.classList.remove('hidden');
        rangeBox.classList.add('hidden');
      } else if (currentBarMode === 'year') {
        yearBox.classList.add('hidden');
        rangeBox.classList.remove('hidden');
      } else {
        yearBox.classList.add('hidden');
        rangeBox.classList.add('hidden');
      }

      drawWeeklyBarChart('weeklyBarCanvasFull', 560, 260, true);
    });
  });

  document.getElementById('chartYearSelect').addEventListener('change', (e) => {
    selectedBarYear = parseInt(e.target.value, 10);
    drawWeeklyBarChart('weeklyBarCanvasFull', 560, 260, true);
  });
  document.getElementById('chartYearRangeSelect').addEventListener('change', (e) => {
    selectedYearRangeLimit = e.target.value === 'all' ? 'all' : parseInt(e.target.value, 10);
    drawWeeklyBarChart('weeklyBarCanvasFull', 560, 260, true);
  });

  // Donut Chart Controls & Drag/Swipe
  document.querySelectorAll('#donutTimeToggle .time-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('#donutTimeToggle .time-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      currentDonutTime = btn.dataset.donutTime;
      updateDonutPeriodUI();
      drawCategoryDonutChart('categoryDonutCanvasFull', 360, 360, false);
    });
  });

  document.getElementById('donutPrevBtn').addEventListener('click', () => stepDonutPeriod(-1));
  document.getElementById('donutNextBtn').addEventListener('click', () => stepDonutPeriod(1));

  // Drag & Swipe on Donut Canvas
  const donutContainer = document.getElementById('donutCanvasContainer');
  if (donutContainer) {
    let startX = 0;
    let isDragging = false;

    donutContainer.addEventListener('touchstart', (e) => {
      startX = e.touches[0].clientX;
      isDragging = true;
    }, { passive: true });

    donutContainer.addEventListener('touchend', (e) => {
      if (!isDragging) return;
      isDragging = false;
      const diff = e.changedTouches[0].clientX - startX;
      if (diff > 45) stepDonutPeriod(-1);
      else if (diff < -45) stepDonutPeriod(1);
    });

    donutContainer.addEventListener('mousedown', (e) => {
      startX = e.clientX;
      isDragging = true;
    });

    window.addEventListener('mouseup', (e) => {
      if (!isDragging) return;
      isDragging = false;
      const diff = e.clientX - startX;
      if (diff > 45) stepDonutPeriod(-1);
      else if (diff < -45) stepDonutPeriod(1);
    });
  }

  // OCR Presets
  document.querySelectorAll('.preset-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const txt = PRESET_RECEIPTS[btn.dataset.preset];
      if (txt) processRawOcrText(txt);
    });
  });

  // File Upload OCR
  document.getElementById('imageFileInput').addEventListener('change', (e) => {
    const file = e.target.files[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = (event) => performClientOCR(event.target.result);
      reader.readAsDataURL(file);
    }
  });

  // Webcam Capture OCR
  document.getElementById('captureWebcamBtn').addEventListener('click', () => {
    const video = document.getElementById('webcamVideo');
    if (video.videoWidth > 0) {
      const tempCanvas = document.createElement('canvas');
      tempCanvas.width = video.videoWidth;
      tempCanvas.height = video.videoHeight;
      const ctx = tempCanvas.getContext('2d');
      ctx.drawImage(video, 0, 0);
      performClientOCR(tempCanvas.toDataURL('image/png'));
    } else {
      processRawOcrText(PRESET_RECEIPTS.winmart);
    }
  });

  // Review Type Switch (Tiền chi / Tiền thu)
  document.getElementById('reviewTypeExpense')?.addEventListener('click', () => {
    reviewModalType = 'expense';
    document.getElementById('reviewTypeExpense').classList.add('active');
    document.getElementById('reviewTypeIncome').classList.remove('active');
    const currentCat = document.querySelector('input[name="reviewCategory"]:checked')?.value || 'food';
    renderCategoryRadioGroup('reviewCategoryGroup', 'reviewCategory', currentCat, 'expense');
  });

  document.getElementById('reviewTypeIncome')?.addEventListener('click', () => {
    reviewModalType = 'income';
    document.getElementById('reviewTypeIncome').classList.add('active');
    document.getElementById('reviewTypeExpense').classList.remove('active');
    const currentCat = document.querySelector('input[name="reviewCategory"]:checked')?.value || 'salary';
    renderCategoryRadioGroup('reviewCategoryGroup', 'reviewCategory', currentCat, 'income');
  });

  // Review OCR Form Submit
  document.getElementById('reviewForm').addEventListener('submit', (e) => {
    e.preventDefault();
    const merchant = document.getElementById('reviewMerchant').value.trim();
    const amount = parseFloat(document.getElementById('reviewAmount').value) || 0;
    const date = document.getElementById('reviewDate').value;
    const note = document.getElementById('reviewNote').value.trim();
    const cat = document.querySelector('input[name="reviewCategory"]:checked')?.value || (reviewModalType === 'income' ? 'salary' : 'other');

    transactions.unshift({
      id: (reviewModalType === 'income' ? 'inc_' : 'exp_') + Date.now(),
      type: reviewModalType,
      merchant: merchant || (reviewModalType === 'income' ? 'Nguồn thu nhập' : 'Cửa hàng / Người nhận'),
      amount: amount,
      date: date,
      category: cat,
      note: note
    });

    saveState();
    closeModal('reviewModal');
    updateUI();
  });

  // Manual Add/Edit Form Submit
  document.getElementById('addEditForm').addEventListener('submit', (e) => {
    e.preventDefault();
    const id = document.getElementById('editExpenseId').value;
    const merchant = document.getElementById('manualMerchant').value.trim();
    const amount = parseFloat(document.getElementById('manualAmount').value) || 0;
    const date = document.getElementById('manualDate').value;
    const note = document.getElementById('manualNote').value.trim();
    const cat = document.querySelector('input[name="manualCategory"]:checked')?.value || 'food';

    if (id) {
      const idx = transactions.findIndex(t => t.id === id);
      if (idx !== -1) {
        transactions[idx] = { ...transactions[idx], merchant, amount, date, category: cat, note, type: manualModalType };
      }
    } else {
      transactions.unshift({
        id: 'trans_' + Date.now(),
        type: manualModalType,
        merchant,
        amount,
        date,
        category: cat,
        note
      });
    }

    saveState();
    closeModal('addEditModal');
    updateUI();
  });

  // Delete Item Event Delegation
  document.addEventListener('click', (e) => {
    const delBtn = e.target.closest('[data-delete-id]');
    if (delBtn) {
      const id = delBtn.dataset.deleteId;
      if (confirm('Bạn có chắc muốn xóa giao dịch này?')) {
        transactions = transactions.filter(t => t.id !== id);
        saveState();
        updateUI();
      }
    }
  });

  // --- 15. PWA SERVICE WORKER & APP INSTALL PROMPT ---
  let deferredPrompt = null;
  const installBtn = document.getElementById('installPwaBtn');

  window.addEventListener('beforeinstallprompt', (e) => {
    e.preventDefault();
    deferredPrompt = e;
    if (installBtn) installBtn.classList.remove('hidden');
  });

  if (installBtn) {
    installBtn.addEventListener('click', async () => {
      if (deferredPrompt) {
        deferredPrompt.prompt();
        const { outcome } = await deferredPrompt.userChoice;
        if (outcome === 'accepted') {
          installBtn.classList.add('hidden');
        }
        deferredPrompt = null;
      } else {
        alert('Để cài đặt ứng dụng:\n- Trên Android/Chrome: Bấm menu 3 chấm (⋮) -> Chọn "Cài đặt ứng dụng" hoặc "Thêm vào màn hình chính".\n- Trên iOS/Safari: Bấm nút Chia sẻ (⎋) -> Chọn "Thêm vào MH chính" (Add to Home Screen).');
      }
    });
  }

  window.addEventListener('appinstalled', () => {
    if (installBtn) installBtn.classList.add('hidden');
    console.log('Finance PWA đã được cài đặt thành công!');
  });

  // Register Service Worker for offline capability
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('/sw.js')
      .then((reg) => console.log('Service Worker registered successfully:', reg.scope))
      .catch((err) => console.warn('Service Worker registration failed:', err));
  }
});

