document.addEventListener('DOMContentLoaded', () => {

  // --- NUI Open/Close & State Logic ---
  function showMenu() {
    document.getElementById('menuWrapper').style.display = 'block';
    setTimeout(() => { document.getElementById('menuWrapper').style.opacity = '1'; }, 10);
    startAutoRefresh();
  }
  
  function hideMenu() {
    document.getElementById('menuWrapper').style.opacity = '0';
    setTimeout(() => { document.getElementById('menuWrapper').style.display = 'none'; }, 500);
    stopAutoRefresh();
  }
  
  function nuiClose() {
    hideMenu();
    $.post(`https://${GetParentResourceName()}/close`, JSON.stringify({}));
  }

  window.addEventListener('message', function(event) {
    const data = event.data;
    if (data.action === 'open') {
        if (data.jobMenu) {
            menuData.WORK.children = data.jobMenu;
        } else {
            menuData.WORK.children = {
                'No Job Actions': { icon: 'fas fa-times-circle', children: null }
            };
        }
        // Store the initial clothing state
        if (data.clothingState) {
            currentClothingState = data.clothingState;
        }
        menuPath = [];
        window.menuPath = menuPath;
        pageIndexes = {};
        renderMenu(); // This draws the menu for the first time
        showMenu();
    } else if (data.action === 'forceClose') {
        hideMenu();
    } else if (data.action === 'updateClothingState') {
        // Update the global state variable
        currentClothingState = data.clothingState;
        // CRITICAL FIX: Directly call the highlight function WITHOUT re-rendering the whole menu
        updateClothingHighlights(currentClothingState);
    } else if (data.action === 'updateStates') {
        console.log('--- JS DEBUG: Received updateStates message ---');
        updateVehicleStates(data.states);
    } else if (data.action === 'immediateUpdate') {
        // NEW: Handle immediate updates for real-time highlighting
        console.log('--- JS DEBUG: Received immediate update ---');
        if (data.clothingState) {
            currentClothingState = data.clothingState;
            updateClothingHighlights(currentClothingState);
        }
        if (data.vehicleStates) {
            updateVehicleStates(data.vehicleStates);
        }
    }
});
  // --- End NUI Logic ---

  document.getElementById('menuWrapper').style.display = 'none';
  document.getElementById('menuWrapper').style.opacity = '0';

  const menuData = {
    'CITIZEN': {
      icon: 'fas fa-user',
      children: {
        'INTERACTION': {
          icon: 'fas fa-handshake',
          children: {
            'PUT IN VEHICLE': { icon: 'fas fa-car-side', event: 'putInVehicle', children: null },
            'TAKE OUT OF VEHICLE': { icon: 'fas fa-car-side', event: 'takeOutOfVehicle', children: null },
            'ROB': { icon: 'fas fa-mask', event: 'robPlayer', children: null },
            'CUFF': { icon: 'fas fa-user-lock', event: 'toggleCuff', children: null },
            'HOSTAGE': { icon: 'fas fa-user', event: 'takeHostage', children: null },
            'ESCORT': { icon: 'fas fa-user-friends', event: 'escortPlayer', children: null },
            'KIDNAP': { icon: 'fas fa-user-friends', event: 'kidnapPlayer', children: null },
          }
        },
        'GIVE CONTACT DETAILS': { icon: 'fas fa-address-card', event: 'giveContactDetails', children: null },
        'HOTDOG SELLING': { icon: 'fas fa-hotdog', event: 'sellHotdog', children: null },
        'GET IN TRUNK': { icon: 'fas fa-truck-loading', event: 'getInTrunk', children: null },
        'CANNABIS SELLING': { icon: 'fas fa-cannabis', event: 'sellCannabis', children: null }
      }
    },
    'GENERAL': {
      icon: 'fas fa-list-alt',
      children: {
        'HOUSE INTERACTION': {
          icon: 'fas fa-home',
          children: {
            'INTERACTION LOCATIONS': {
              icon: 'fas fa-map-marker-alt',
              children: {
                'SET STASH': { icon: 'fas fa-box-open', event: 'setHouseLocation', locationType: 'stash', children: null },
                'SET WARDROBE': { icon: 'fas fa-tshirt', event: 'setHouseLocation', locationType: 'wardrobe', children: null },
                'SET LOGOUT': { icon: 'fas fa-door-open', event: 'setHouseLocation', locationType: 'logout', children: null }
              }
            },
            'GIVE HOUSE KEYS': { icon: 'fas fa-key', event: 'giveHouseKey', children: null },
            'DECORATE HOUSE': { icon: 'fas fa-couch', event: 'decorateHouse', children: null },
            'REMOVE HOUSE KEYS': { icon: 'fas fa-key', event: 'removeHouseKey', children: null },
            'TOGGLE DOORLOCK': { icon: 'fas fa-door-closed', event: 'toggleDoorLock', children: null }
          }
        },
        'CLOTHING': {
          icon: 'fas fa-tshirt',
          children: {
            'Mask':    { icon: 'fas fa-mask',        event: 'FxRadialMenu:ToggleClothing', 'data-item': 'mask',  data: { item: 'mask' },  children: null },
            'Hat':     { icon: 'fas fa-hat-cowboy',  event: 'FxRadialMenu:ToggleClothing', 'data-item': 'hat',   data: { item: 'hat' },   children: null },
            'Glasses': { icon: 'fas fa-glasses',     event: 'FxRadialMenu:ToggleClothing', 'data-item': 'glasses', data: { item: 'glasses' }, children: null },
            'Jacket':  { icon: 'fas fa-mitten',      event: 'FxRadialMenu:ToggleClothing', 'data-item': 'jacket', data: { item: 'jacket' }, children: null },
            'Shirt':   { icon: 'fas fa-tshirt',      event: 'FxRadialMenu:ToggleClothing', 'data-item': 'shirt', data: { item: 'shirt' }, children: null },
            'Pants':   { icon: 'fas fa-male',        event: 'FxRadialMenu:ToggleClothing', 'data-item': 'pants', data: { item: 'pants' }, children: null },
            'Shoes':   { icon: 'fas fa-shoe-prints', event: 'FxRadialMenu:ToggleClothing', 'data-item': 'shoes', data: { item: 'shoes' }, children: null },
            'Bag':     { icon: 'fas fa-briefcase',   event: 'FxRadialMenu:ToggleClothing', 'data-item': 'bag',   data: { item: 'bag' },   children: null },
            'Vest':    { icon: 'fas fa-shield-alt',  event: 'FxRadialMenu:ToggleClothing', 'data-item': 'vest',  data: { item: 'vest' },  children: null },
            'Gloves':  { icon: 'fas fa-hand-paper',  event: 'FxRadialMenu:ToggleClothing', 'data-item': 'gloves', data: { item: 'gloves' }, children: null },
            'Extras':  {
              icon: 'fas fa-star',
              children: {
                'Ears':       { icon: 'fas fa-deaf',      event: 'FxRadialMenu:ToggleClothing', 'data-item': 'ears',     data: { item: 'ears' },     children: null },
                'Necklace':   { icon: 'fas fa-link',      event: 'FxRadialMenu:ToggleClothing', 'data-item': 'neck', data: { item: 'neck' }, children: null },
                'Watches':    { icon: 'fas fa-clock',     event: 'FxRadialMenu:ToggleClothing', 'data-item': 'watch',    data: { item: 'watch' },    children: null },
                'Bracelet':   { icon: 'fas fa-link',      event: 'FxRadialMenu:ToggleClothing', 'data-item': 'bracelet', data: { item: 'bracelet' }, children: null },
              }
            },
          }
        },
        'VEHICLE': {
          icon: 'fas fa-car',
          children: {
            'Engine': {
              icon: 'fas fa-cogs',
              children: {
                'Engine On': { icon: 'fas fa-play', event: 'vehicleEngineOn', 'data-action': 'vehicleEngineOn', children: null },
                'Engine Off': { icon: 'fas fa-stop', event: 'vehicleEngineOff', 'data-action': 'vehicleEngineOff', children: null }
              }
            },
            'Lights': {
              icon: 'fas fa-lightbulb',
              children: {
                'Light On': { icon: 'fas fa-lightbulb', event: 'vehicleLightOn', 'data-action': 'vehicleLightOn', children: null },
                'Light Off': { icon: 'fas fa-lightbulb', event: 'vehicleLightOff', 'data-action': 'vehicleLightOff', children: null }
              }
            },
            'Seat Shuffle': {
              icon: 'fas fa-exchange-alt',
              children: {
                'Driver': { icon: 'fas fa-user', event: 'vehicleSeatDriver', 'data-action': 'vehicleSeatDriver', children: null },
                'Front Passenger': { icon: 'fas fa-user-friends', event: 'vehicleSeatPassenger', 'data-action': 'vehicleSeatPassenger', children: null },
                'Rear Left': { icon: 'fas fa-user-friends', event: 'vehicleSeatRearLeft', 'data-action': 'vehicleSeatRearLeft', children: null },
                'Rear Right': { icon: 'fas fa-user-friends', event: 'vehicleSeatRearRight', 'data-action': 'vehicleSeatRearRight', children: null }
              }
            },
            'Window Control': {
              icon: 'fas fa-window-maximize',
              children: {
                'Front Left': { icon: 'fas fa-window-maximize', event: 'vehicleWindowFrontLeft', 'data-action': 'vehicleWindowFrontLeft', children: null },
                'Front Right': { icon: 'fas fa-window-maximize', event: 'vehicleWindowFrontRight', 'data-action': 'vehicleWindowFrontRight', children: null },
                'Rear Left': { icon: 'fas fa-window-maximize', event: 'vehicleWindowRearLeft', 'data-action': 'vehicleWindowRearLeft', children: null },
                'Rear Right': { icon: 'fas fa-window-maximize', event: 'vehicleWindowRearRight', 'data-action': 'vehicleWindowRearRight', children: null }
              }
            },
            'Door': {
              icon: 'fas fa-door-open',
              children: {
                'Front Left': { icon: 'fas fa-door-open', event: 'vehicleDoorFrontLeft', 'data-action': 'vehicleDoorFrontLeft', children: null },
                'Front Right': { icon: 'fas fa-door-open', event: 'vehicleDoorFrontRight', 'data-action': 'vehicleDoorFrontRight', children: null },
                'Rear Left': { icon: 'fas fa-door-open', event: 'vehicleDoorRearLeft', 'data-action': 'vehicleDoorRearLeft', children: null },
                'Rear Right': { icon: 'fas fa-door-open', event: 'vehicleDoorRearRight', 'data-action': 'vehicleDoorRearRight', children: null },
                'Trunk': { icon: 'fas fa-archive', event: 'vehicleDoorTrunk', 'data-action': 'vehicleDoorTrunk', children: null },
                'Hood': { icon: 'fas fa-archive', event: 'vehicleDoorHood', 'data-action': 'vehicleDoorHood', children: null }
              }
            },
            'Lock': {
              icon: 'fas fa-lock',
              children: {
                'Lock': { icon: 'fas fa-lock', event: 'vehicleLock', 'data-action': 'vehicleLock', children: null },
                'Unlock': { icon: 'fas fa-lock-open', event: 'vehicleUnlock', 'data-action': 'vehicleUnlock', children: null }
              }
            },
            'Keys': {
              icon: 'fas fa-key',
              children: {
                'Give Keys': { icon: 'fas fa-key', event: 'vehicleGiveKeys', 'data-action': 'vehicleGiveKeys', children: null }
              }
            }
          }
        }
      }
    },
    'WORK': {
      icon: 'fas fa-briefcase',
      children: {} // This is empty and will be filled by Lua
    }
  };

  let menuPath = [];
  window.menuPath = menuPath; // Make menuPath globally accessible
  let currentClothingState = {};
  let pageIndexes = {};
  const dynamicMenuContainer = document.getElementById('dynamicMenuContainer');
  const mainCategoriesRow = document.getElementById('mainCategoriesRow');
  const notification = document.getElementById('notification');
  const prevPageBtn = document.getElementById('prevPageBtn');
  const nextPageBtn = document.getElementById('nextPageBtn');

  // Auto-refresh system
  let autoRefreshInterval = null;

  function startAutoRefresh() {
    if (autoRefreshInterval) clearInterval(autoRefreshInterval);
    autoRefreshInterval = setInterval(() => {
        if (document.getElementById('menuWrapper').style.display !== 'none') {
            // Auto-request updates every 2 seconds while menu is open
            $.post(`https://${GetParentResourceName()}/requestStates`, JSON.stringify({}));
            $.post(`https://${GetParentResourceName()}/requestClothingUpdate`, JSON.stringify({}));
        }
    }, 2000);
  }

  function stopAutoRefresh() {
    if (autoRefreshInterval) {
        clearInterval(autoRefreshInterval);
        autoRefreshInterval = null;
    }
  }

  // --- MENU BUTTONS PER ROW RULE ---
  function getItemsPerPage(level, currentPage = 0, parentKey = null) {
    if (parentKey === 'NPC Guard') {
        return 6;
    }
    // INTERACTION LOCATIONS submenu එකට 6ක්
    if (parentKey === 'INTERACTION LOCATIONS') {
        return 6;
    }
    // GENERAL > CLOTHING > Extras submenu එකට 6ක්
    if (menuPath[0] === 'GENERAL' && menuPath[1] === 'CLOTHING' && parentKey === 'Extras') {
        return 6;
    }
    // GENERAL > VEHICLE > ... (level 2) submenu එකට 6ක් (raw 6)
    if (menuPath[0] === 'GENERAL' && menuPath[1] === 'VEHICLE' && level === 2) {
        return 6;
    }
    // GENERAL > CLOTHING > ... (level 2) submenu එකට 5ක් (raw 5)
    if (menuPath[0] === 'GENERAL' && menuPath[1] === 'CLOTHING' && level === 2) {
        return 5;
    }
    switch (level) {
        case 0:
            return 4;
        case 3:
            return 4;
        default:
            return 5;
    }
  }

  function handleHexClick(itemName, level, item) {
    // Check if the button has a submenu
    if (item.children) {
        // If it has children, it's a "menu button".
        // Update the path and re-render the menu to show the selection.
        menuPath = menuPath.slice(0, level);
        menuPath.push(itemName);
        window.menuPath = menuPath; // Update global reference
        const pageKey = menuPath.join('/');
        pageIndexes[pageKey] = 0;
        renderMenu();
    } else {
        // If it has no children, it's an "action button".
        // Perform the action and immediately update highlighting
        if (item.event) {
            let eventData = {
                action: item.event,
                model: item.model || null,
                data: null
            };
            if (item.data && typeof item.data === 'object' && item.data.item) {
                eventData.data = { id: item.data.item };
            }
            if (item.locationType) {
                eventData.locationType = item.locationType;
            }
            
            // Send action to Lua with proper data structure
            $.post(`https://${GetParentResourceName()}/performAction`, JSON.stringify(eventData))
                .done(() => {
                    // Force clothing state refresh
                    if (item.event && item.event.includes('Clothing')) {
                        setTimeout(() => {
                            $.post(`https://${GetParentResourceName()}/requestClothingUpdate`, JSON.stringify({}));
                        }, 200); // Give more time for clothing change
                    }
                });
        }
    }
  }

  function renderMenu() {
    dynamicMenuContainer.innerHTML = '';
    mainCategoriesRow.style.display = 'flex';
    document.querySelectorAll('#mainCategoriesRow .hexagon').forEach(h => {
      h.classList.remove('selected');
      h.setAttribute('aria-expanded', 'false');
    });
    prevPageBtn.classList.remove('has-prev-indicator');
    nextPageBtn.classList.remove('has-next-indicator');
    
    if (menuPath.length === 0) {
      dynamicMenuContainer.style.display = 'none';
      return;
    }
    
    dynamicMenuContainer.style.display = 'flex';
    const mainCategoryName = menuPath[0];
    const mainCategoryHexagon = mainCategoriesRow.querySelector(`[data-category="${mainCategoryName}"]`);
    if (mainCategoryHexagon) {
      mainCategoryHexagon.classList.add('selected');
      mainCategoryHexagon.setAttribute('aria-expanded', 'true');
    }
    
    let currentLevelData = menuData;
    menuPath.forEach((pathItem, level) => {
      const children = currentLevelData[pathItem]?.children;
      if (!children) return;
      const pageKey = menuPath.slice(0, level + 1).join('/');
      const currentPage = pageIndexes[pageKey] || 0;
      let startIndex = 0;
      for (let i = 0; i < currentPage; i++) { 
        startIndex += getItemsPerPage(level, i, pathItem); 
      }
      const itemsToDisplayOnThisPage = getItemsPerPage(level, currentPage, pathItem);
      const animateThisRow = (level === menuPath.length - 1);
      renderRow(children, level, startIndex, itemsToDisplayOnThisPage, animateThisRow, menuPath[level + 1]);
      currentLevelData = children;
    });

    if (menuPath.length > 0) {
        const currentLevelIndex = menuPath.length - 1;
        const pageKey = menuPath.join('/');
        let currentLevelDataForPagination = menuData;
        menuPath.forEach(p => { 
            currentLevelDataForPagination = currentLevelDataForPagination[p]?.children || {}; 
        });
        const totalItems = Object.keys(currentLevelDataForPagination).length;
        const currentPage = pageIndexes[pageKey] || 0;
        let itemsSeen = 0;
        const parentKeyForPagination = menuPath[currentLevelIndex];
        for (let i = 0; i <= currentPage; i++) { 
            itemsSeen += getItemsPerPage(currentLevelIndex, i, parentKeyForPagination); 
        }
        if (itemsSeen < totalItems) { 
            nextPageBtn.classList.add('has-next-indicator'); 
        }
        if (currentPage > 0 || menuPath.length > 1) { 
            prevPageBtn.classList.add('has-prev-indicator'); 
        }
    }
    
    // IMPROVED: Multiple requests for comprehensive state updates
    setTimeout(() => {
        // Always request both states after menu render
        $.post(`https://${GetParentResourceName()}/requestStates`, JSON.stringify({}));
        $.post(`https://${GetParentResourceName()}/requestClothingUpdate`, JSON.stringify({}));
    }, 100);
  }

  function renderRow(items, level, startIndex, itemsToDisplay, animate, selectedKey) {
    const row = document.createElement('div');
    row.className = 'hexagon-row';
    if (animate) { row.classList.add('fade-slide-in'); }

    const itemKeys = Object.keys(items);
    const visibleKeys = itemKeys.slice(startIndex, startIndex + itemsToDisplay);

    visibleKeys.forEach((key, index) => {
        const item = items[key];
        const hex = document.createElement('div');
        hex.className = 'hexagon';
        
        // CRITICAL FIX: Set data-action for vehicle buttons
        if (item.event) {
            hex.dataset.action = item.event;
            console.log(`Setting data-action="${item.event}" for button "${key}"`);
        }
        
        // Clothing items fix
        if (item['data-item']) {
            hex.dataset.item = item['data-item'];
        }

        if (animate) { hex.style.animationDelay = `${index * 0.07}s`; }
        if (selectedKey === key) {
            hex.classList.add('selected');
        }
        
        // FIXED REGEX: Remove the ? after ^
        const label = key.replace(/^\d+\.\s*/, '');
        
        hex.innerHTML = `<i class="${item.icon || ''} icon" aria-hidden="true"></i><div class="hexagon-label">${label || ''}</div>`;
        hex.addEventListener('click', () => handleHexClick(key, level + 1, item));
        row.appendChild(hex);
    });

    for (let i = visibleKeys.length; i < itemsToDisplay; i++) {
        const emptyHex = document.createElement('div');
        emptyHex.className = 'hexagon';
        if (animate) { emptyHex.style.animationDelay = `${i * 0.07}s`; }
        emptyHex.innerHTML = `<i class="fas fa-circle icon" style="opacity:0.1;"></i>`;
        row.appendChild(emptyHex);
    }
    dynamicMenuContainer.prepend(row);
  }

  function showNotification(message) {
    notification.textContent = message;
    notification.classList.add('show');
    setTimeout(() => { notification.classList.remove('show'); }, 2200);
  }

  mainCategoriesRow.querySelectorAll('.hexagon').forEach(hex => {
    hex.addEventListener('click', () => {
      const category = hex.dataset.category;
      handleHexClick(category, 0, menuData[category]);
    });
  });

  document.getElementById('exitBtn').addEventListener('click', nuiClose);

  prevPageBtn.addEventListener('click', () => {
    if (menuPath.length > 0) {
      const pageKey = menuPath.join('/');
      let currentPage = pageIndexes[pageKey] || 0;
      if (currentPage > 0) {
          pageIndexes[pageKey] = currentPage - 1;
      } else {
          menuPath.pop();
          window.menuPath = menuPath;
      }
      renderMenu();
    }
  });

  nextPageBtn.addEventListener('click', () => {
    if (menuPath.length === 0) return;
    const pageKey = menuPath.join('/');
    let currentLevelData = menuData;
    menuPath.forEach(p => { currentLevelData = currentLevelData[p]?.children || {}; });
    const totalItems = Object.keys(currentLevelData).length;
    let currentPage = pageIndexes[pageKey] || 0;
    let itemsSeen = 0;
    const parentKeyForPagination = menuPath[menuPath.length-1];
    for (let i = 0; i <= currentPage; i++) { itemsSeen += getItemsPerPage(menuPath.length - 1, i, parentKeyForPagination); }
    if (itemsSeen < totalItems) {
        pageIndexes[pageKey] = currentPage + 1;
        renderMenu();
    }
  });

  document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape' || e.key === 'Backspace') {
      e.preventDefault();
      nuiClose();
    }
  });

  // IMPROVED updateClothingHighlights function
  function updateClothingHighlights(state) {
    console.log('--- JS DEBUG: updateClothingHighlights function STARTED ---');
    if (!state) {
        console.log('--- JS DEBUG: State is empty, stopping. ---');
        return;
    }

    // IMMEDIATE update without setTimeout for better responsiveness
    requestAnimationFrame(() => {
        const allHexagons = document.querySelectorAll('.hexagon');
        console.log(`Found ${allHexagons.length} total buttons for clothing check`);
        
        // CRITICAL: Only clear clothing-related states, preserve vehicle states
        allHexagons.forEach(hex => {
            const item = hex.dataset.item;
            if (item) {
                hex.classList.remove('active-gold');
            }
        });
        
        allHexagons.forEach(hex => {
            const label = hex.querySelector('.hexagon-label');
            if (label) {
                const labelText = label.textContent.trim().toLowerCase();
                
                // Enhanced clothing mappings
                const clothingMappings = {
                    'mask': 'mask',
                    'hat': 'hat', 
                    'glasses': 'glasses',
                    'jacket': 'jacket',
                    'shirt': 'shirt',
                    'pants': 'pants',
                    'shoes': 'shoes',
                    'bag': 'bag',
                    'vest': 'vest',
                    'gloves': 'gloves',
                    'ears': 'ears',
                    'necklace': 'neck',
                    'watches': 'watch',
                    'bracelet': 'bracelet'
                };
                
                const clothingItem = clothingMappings[labelText];
                if (clothingItem && state[clothingItem]) {
                    hex.dataset.item = clothingItem;
                    if (state[clothingItem].on) {
                        console.log(`Adding gold to ${clothingItem} button (${labelText})`);
                        hex.classList.add('active-gold');
                    } else {
                        console.log(`Removing gold from ${clothingItem} button (${labelText})`);
                        hex.classList.remove('active-gold');
                    }
                }
            }
        });
        
        console.log('--- JS DEBUG: updateClothingHighlights function FINISHED ---');
    });
  }
});

// IMPROVED updateVehicleStates function
function updateVehicleStates(states) {
    console.log('--- JS DEBUG: Updating vehicle states ---');
    console.log('States object:', JSON.stringify(states, null, 2));
    
    // IMMEDIATE update without setTimeout for better responsiveness
    requestAnimationFrame(() => {
        // Find all hexagon buttons
        const allHexagons = document.querySelectorAll('.hexagon');
        console.log(`Found ${allHexagons.length} hexagon buttons`);
        
        // CRITICAL: Only clear vehicle-related states, preserve clothing states
        allHexagons.forEach(hex => {
            const action = hex.dataset.action;
            if (action && action.includes('vehicle')) {
                hex.classList.remove('active-gold');
            }
        });
        
        // Apply vehicle states based on text content matching
        allHexagons.forEach(hex => {
            const label = hex.querySelector('.hexagon-label');
            if (label) {
                const labelText = label.textContent.trim();
                
                // Engine states
                if (labelText === 'Engine On' && states.vehicleEngineOn) {
                    console.log('Adding gold to Engine On button');
                    hex.classList.add('active-gold');
                    hex.dataset.action = 'vehicleEngineOn';
                }
                if (labelText === 'Engine Off' && states.vehicleEngineOff) {
                    console.log('Adding gold to Engine Off button');
                    hex.classList.add('active-gold');
                    hex.dataset.action = 'vehicleEngineOff';
                }
                
                // Light states
                if (labelText === 'Light On' && states.vehicleLightOn) {
                    console.log('Adding gold to Light On button');
                    hex.classList.add('active-gold');
                    hex.dataset.action = 'vehicleLightOn';
                }
                if (labelText === 'Light Off' && states.vehicleLightOff) {
                    console.log('Adding gold to Light Off button');
                    hex.classList.add('active-gold');
                    hex.dataset.action = 'vehicleLightOff';
                }
                
                // Door states
                const doorMappings = {
                    'Front Left': 'vehicleDoorFrontLeft',
                    'Front Right': 'vehicleDoorFrontRight', 
                    'Rear Left': 'vehicleDoorRearLeft',
                    'Rear Right': 'vehicleDoorRearRight',
                    'Hood': 'vehicleDoorHood',
                    'Trunk': 'vehicleDoorTrunk'
                };
                
                // Check if we're in a door menu
                const isInDoorMenu = window.menuPath && window.menuPath.includes('Door');
                if (isInDoorMenu && doorMappings[labelText] && states[doorMappings[labelText]]) {
                    console.log(`Adding gold to ${labelText} door button`);
                    hex.classList.add('active-gold');
                    hex.dataset.action = doorMappings[labelText];
                }
                
                // Window states
                const windowMappings = {
                    'Front Left': 'vehicleWindowFrontLeft',
                    'Front Right': 'vehicleWindowFrontRight',
                    'Rear Left': 'vehicleWindowRearLeft', 
                    'Rear Right': 'vehicleWindowRearRight'
                };
                
                // Only for window menus
                const isInWindowMenu = window.menuPath && window.menuPath.includes('Window Control');
                if (isInWindowMenu && windowMappings[labelText] && states[windowMappings[labelText]]) {
                    console.log(`Adding gold to ${labelText} window button`);
                    hex.classList.add('active-gold');
                    hex.dataset.action = windowMappings[labelText];
                }
                
                // Seat states  
                const seatMappings = {
                    'Driver': 'vehicleSeatDriver',
                    'Front Passenger': 'vehicleSeatPassenger',
                    'Rear Left': 'vehicleSeatRearLeft',
                    'Rear Right': 'vehicleSeatRearRight'
                };
                
                const isInSeatMenu = window.menuPath && window.menuPath.includes('Seat Shuffle');
                if (isInSeatMenu && seatMappings[labelText] && states[seatMappings[labelText]]) {
                    console.log(`Adding gold to ${labelText} seat button`);
                    hex.classList.add('active-gold');
                    hex.dataset.action = seatMappings[labelText];
                }
            }
        });
        
        console.log('--- JS DEBUG: Vehicle state highlighting completed ---');
    });
}
