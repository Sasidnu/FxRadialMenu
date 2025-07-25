Config = {}

Config.OpenKey = "F1" 

Config.JobMenus = {
    ['police'] = {
        ['Police Actions'] = {
            icon = 'fas fa-shield-alt',
            children = {
                ['Jail'] = { icon = 'fas fa-gavel', event = 'jailPlayer', children = nil },
                ['Check Status'] = { icon = 'fas fa-info-circle', event = 'checkPlayerStatus', children = nil },
                ['Escort'] = { icon = 'fas fa-user-friends', event = 'escortPlayer', children = nil },
                ['Search'] = { icon = 'fas fa-search', event = 'searchPlayer', children = nil },
                ['NPC Guard'] = {
                    icon = 'fas fa-user-shield',
                    children = {
                        ['1. Call Guard'] = { icon = 'fas fa-user-plus', event = 'policeSpawnGuard', children = nil },
                        ['2. Dismiss Guard'] = { icon = 'fas fa-user-slash', event = 'policeDismissGuard', children = nil },
                        ['3. Follow/Stay'] = { icon = 'fas fa-user-friends', event = 'policeToggleGuardFollow', children = nil },
                        ['4. Attack Target'] = { icon = 'fas fa-bullseye', event = 'policeGuardAttackTarget', children = nil },
                        ['5. Stop'] = { icon = 'fas fa-hand-paper', event = 'policeGuardStop', children = nil }
                    }
                },
            }
        },
        ['Objects'] = { 
            icon = 'fas fa-cube', 
            children = {
                ['Barrier'] = { icon = 'fas fa-door-closed', event = 'spawnObject', model = 'prop_barrier_work05', children = nil },
                ['Cone'] = { icon = 'fas fa-traffic-light', event = 'spawnObject', model = 'prop_roadcone02a', children = nil },
                ['Spike Strips'] = { icon = 'fas fa-road', event = 'spawnObject', model = 'p_stinger_04', children = nil },
                ['Remove Object'] = { icon = 'fas fa-trash-alt', event = 'removeClosestObject', children = nil },
            }
        },
    },
    ['ems'] = {
        ['EMS Actions'] = {
            icon = 'fas fa-briefcase-medical',
            children = {
                ['Revive'] = { icon = 'fas fa-heartbeat', event = 'revivePlayer', children = nil },
                ['Heal'] = { icon = 'fas fa-band-aid', event = 'healPlayer', children = nil },
                ['Check Status'] = { icon = 'fas fa-info-circle', event = 'checkPlayerStatus', children = nil },
                ['Put in Vehicle'] = { icon = 'fas fa-car-side', event = 'putInVehicle', children = nil },
            }
        },
        ['Objects'] = { 
            icon = 'fas fa-cube', 
            children = {
                ['Cone'] = { icon = 'fas fa-traffic-light', event = 'spawnObject', model = 'prop_roadcone02a', children = nil },
                ['Stretcher'] = { icon = 'fas fa-stretcher', event = 'getStretcher', children = nil },
                ['Remove Object'] = { icon = 'fas fa-trash-alt', event = 'removeClosestObject', children = nil },
            }
        },
    },
    ['ambulance'] = {
        ['EMS Actions'] = {
            icon = 'fas fa-briefcase-medical',
            children = {
                ['Revive'] = { icon = 'fas fa-heartbeat', event = 'revivePlayer', children = nil },
                ['Heal'] = { icon = 'fas fa-band-aid', event = 'healPlayer', children = nil },
                ['Check Status'] = { icon = 'fas fa-info-circle', event = 'checkPlayerStatus', children = nil },
                ['Put in Vehicle'] = { icon = 'fas fa-car-side', event = 'putInVehicle', children = nil },
            }
        },
        ['Objects'] = { 
            icon = 'fas fa-cube', 
            children = {
                ['Cone'] = { icon = 'fas fa-traffic-light', event = 'spawnObject', model = 'prop_roadcone02a', children = nil },
                ['Stretcher'] = { icon = 'fas fa-stretcher', event = 'getStretcher', children = nil },
                ['Remove Object'] = { icon = 'fas fa-trash-alt', event = 'removeClosestObject', children = nil },
            }
        },
    },
    ['mechanic'] = {
        ['Mechanic Actions'] = {
            icon = 'fas fa-tools',
            children = {
                ['Repair Vehicle'] = { icon = 'fas fa-car-crash', event = 'mechanic:repair', children = nil },
                ['Clean Vehicle'] = { icon = 'fas fa-soap', event = 'mechanic:clean', children = nil },
                ['Tow Vehicle'] = { icon = 'fas fa-truck-pickup', event = 'mechanic:tow', children = nil },
            }
        },
        ['Objects'] = {
            icon = 'fas fa-cube',
            children = {
                ['Cone'] = { icon = 'fas fa-traffic-light', event = 'spawnObject', model = 'prop_roadcone02a', children = nil },
                ['Barrier'] = { icon = 'fas fa-door-closed', event = 'spawnObject', model = 'prop_barrier_work05', children = nil },
                ['Remove Object'] = { icon = 'fas fa-trash-alt', event = 'removeClosestObject', children = nil },
            }
        }
    }
}

-- Remove the MenuItems section from config since it's already in JavaScript