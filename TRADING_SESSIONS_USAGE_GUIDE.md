# 🎯 TRADING SESSIONS - BEST PRACTICES & USAGE GUIDE

## 📌 OVERVIEW

Trading Sessions feature memungkinkan Anda membatasi trading pada jam-jam pasar tertentu:
- **London Session** (15:00-23:30 WIB / 08:00-16:30 GMT)
- **New York Session** (20:00-04:00 WIB / 13:00-21:00 GMT)
- **Asia Session** (05:00-15:00 WIB / 22:00-08:00 GMT)

---

## ✅ FITUR LENGKAP

### 1. Enable/Disable Trading Sessions
```
Panel Kontrol → Trading Sessions (WIB/UTC+7)
Checkbox: "Enable Trading Session Restrictions"
- Default: ON (True)
```

### 2. Per-Session Control
Setiap session memiliki:
- ✅ Checkbox untuk enable/disable session tersebut
- ⏰ Time input untuk start time (HH:MM format)
- ⏰ Time input untuk end time (HH:MM format)

### 3. Flexible Time Format
```
Format yang didukung:
- HH:MM (24-hour)
- Contoh: 15:00, 23:30, 04:00 (next day)
```

---

## 🔧 KONFIGURASI

### Default Settings (config_manager.py)
```python
'trading_sessions_enabled': True,

'london_session_enabled': True,
'london_start': '15:00',   # WIB
'london_end': '23:30',     # WIB

'ny_session_enabled': True,
'ny_start': '20:00',       # WIB
'ny_end': '04:00',         # WIB (next day)

'asia_session_enabled': False,
'asia_start': '05:00',     # WIB
'asia_end': '15:00',       # WIB
```

### Mengubah Settings
1. Edit di GUI
2. Switch bot (auto-save)
3. Settings tersimpan di:
   - Memory
   - hft_session.json
   - Custom config files

---

## 💾 PERSISTENCE

### Automatic Saving

Trading sessions disimpan **otomatis** saat:

| Action | Simpan Ke | Method |
|--------|-----------|--------|
| Switch Bot | Memory + hft_session.json | save_gui_config_to_bot() |
| Save Config | Custom file | save_config() |
| Create Bot | Memory + hft_session.json | add_bot() |
| Close App | hft_session.json | save_session() |

### Manual Loading

Trading sessions di-load **otomatis** saat:

| Event | Load Dari | Method |
|-------|-----------|--------|
| App Start | hft_session.json | load_session() |
| Load Config | Custom file | load_config_dialog() |
| Switch Bot | Memory | on_bot_selected() |

---

## 🚀 USAGE EXAMPLES

### Example 1: Setup London + NY Sessions Only
```
1. Panel Kontrol → Trading Sessions
2. ✅ Enable Trading Session Restrictions
3. ✅ London Session: 15:00 - 23:30
4. ✅ NY Session: 20:00 - 04:00
5. ❌ Asia Session: (unchecked)
6. Switch bot / Save config
7. Settings auto-saved
```

### Example 2: 24/7 Trading (All Sessions)
```
1. Panel Kontrol → Trading Sessions
2. ✅ Enable Trading Session Restrictions
3. ✅ London Session: 15:00 - 23:30
4. ✅ NY Session: 20:00 - 04:00
5. ✅ Asia Session: 05:00 - 15:00
6. Bot sekarang bisa trade 24/7
```

### Example 3: Disable Session Restrictions
```
1. Panel Kontrol → Trading Sessions
2. ❌ Enable Trading Session Restrictions (UNCHECK)
3. Bot bisa trade kapan saja
```

### Example 4: Custom Times
```
1. Edit times untuk session apapun
2. Contoh: London 08:00 - 17:00 (custom)
3. Switch bot atau Save Config
4. Settings disimpan dengan times baru
```

---

## 📊 VERIFICATION CHECKLIST

### ✓ Settings Tersimpan
```
Buka hft_session.json:
{
    "bots": {
        "Bot_Name": {
            "config": {
                "trading_sessions_enabled": true,
                "london_session_enabled": true,
                "london_start": "15:00",
                "london_end": "23:30",
                ...
            }
        }
    }
}
```

### ✓ Settings Ter-restore
```
1. Edit London start → 16:00
2. Switch bot (trigger save)
3. Close & reopen app
4. Check London start → harus 16:00
```

### ✓ Multiple Bots Different Settings
```
1. Bot_1: London + NY
2. Bot_2: Asia only
3. Switch antar bots
4. Setiap bot maintains own settings
```

---

## ⚠️ TROUBLESHOOTING

### Issue 1: Settings tidak ter-save
**Penyebab**: Tidak switch bot / tidak save config setelah edit

**Solusi**:
```
1. Ubah trading sessions
2. Switch ke bot lain (trigger auto-save)
   ATAU
   Click "Save Config" button
3. Check hft_session.json apakah sudah update
```

### Issue 2: Settings ter-restore tapi tidak dipakai bot
**Penyebab**: Bot logic tidak check trading sessions

**Solusi**: Pastikan bot core code memiliki:
```python
if self.config.get('trading_sessions_enabled'):
    if not self.is_trading_session_allowed():
        return  # Don't trade outside sessions
```

### Issue 3: Time format error
**Penyebab**: Input format salah (bukan HH:MM)

**Solusi**:
```
Format yang benar: HH:MM
Contoh: 15:00, 04:00, 23:30
Jangan: 3:00 PM, 15, 15.00
```

### Issue 4: Session overlap handling
**Scenario**: NY Session 20:00-04:00 melewati midnight

**How it works**:
```
20:00 (hari 1) → 23:59 (hari 1) → Allowed ✓
00:00 (hari 2) → 04:00 (hari 2) → Allowed ✓
04:01 (hari 2) → 19:59 (hari 2) → Not allowed ✗
```

---

## 🔐 DATA STRUCTURE

### In Memory (while app running)
```python
self.bots[bot_id]['config'] = {
    'trading_sessions_enabled': True/False,
    'london_session_enabled': True/False,
    'london_start': '15:00',
    'london_end': '23:30',
    'ny_session_enabled': True/False,
    'ny_start': '20:00',
    'ny_end': '04:00',
    'asia_session_enabled': True/False,
    'asia_start': '05:00',
    'asia_end': '15:00',
    # ... other config fields
}
```

### In hft_session.json (persisted)
```json
{
    "active_bot_id": "Bot_1",
    "bots": {
        "Bot_1": {
            "config": {
                "trading_sessions_enabled": true,
                "london_session_enabled": true,
                "london_start": "15:00",
                "london_end": "23:30",
                // ... etc
            }
        }
    }
}
```

### In Custom Config File (export)
```json
{
    "bot_id": "Bot_1",
    "trading_sessions_enabled": true,
    "london_session_enabled": true,
    "london_start": "15:00",
    "london_end": "23:30",
    // ... etc
}
```

---

## 📝 RECOMMENDED WORKFLOWS

### Workflow 1: Setup Once, Use Everywhere
```
1. Configure trading sessions untuk Bot_1
2. Save Config → "Bot_1_config.json"
3. Create Bot_2
4. Load Config → "Bot_1_config.json"
5. Bot_2 sekarang punya settings yang sama
```

### Workflow 2: Multiple Strategies
```
1. Bot_Scalper: London + NY (high volatility)
2. Bot_Range: Asia (low volatility)
3. Bot_Swing: 24/7 (swing trading)
4. Setiap bot dengan session strategy berbeda
```

### Workflow 3: Backup & Recovery
```
1. Regular Save Config → configs/ folder
2. If app crash: Load last saved config
3. Trading sessions ter-restore otomatis
```

---

## 🎯 TIPS & TRICKS

### Tip 1: Test Trading Sessions
```
Misalnya London session 15:00-23:30
Test dengan waktu yang lebih dekat:
1. Ubah ke London 14:59-15:01 (1 menit window)
2. Run bot saat 14:59-15:01
3. Bot harusnya trade HANYA di window tersebut
```

### Tip 2: Combine dengan Risk Management
```
Trading Sessions: WHEN to trade
Risk Management: HOW MUCH to risk
Combining both = Optimal trading
```

### Tip 3: Use Timezone Carefully
```
Settings stored dalam WIB (UTC+7)
Jangan lupa timezone saat setting times
Contoh: London 08:00 GMT = 15:00 WIB
```

---

## ✅ VERIFICATION COMMANDS

### Check Config Structure
```python
# Print trading sessions config
bot_config = gui.bots['Bot_1']['config']
print(bot_config.get('trading_sessions_enabled'))
print(bot_config.get('london_start'))
```

### Check Session File
```bash
# View hft_session.json
cat hft_session.json | grep trading_sessions_enabled

# Parse with python
import json
with open('hft_session.json') as f:
    data = json.load(f)
    print(data['bots']['Bot_1']['config']['london_start'])
```

### Check Persistence
```python
# Before
old_config = copy.deepcopy(gui.bots['Bot_1']['config'])

# Make change
gui.london_start_var.set('16:00')

# Save
gui.save_gui_config_to_bot('Bot_1')

# After
new_config = gui.bots['Bot_1']['config']
assert new_config['london_start'] == '16:00'
```

---

## 📞 SUPPORT

If trading sessions not working:

1. ✅ Check enable checkbox is ON
2. ✅ Check times format (HH:MM)
3. ✅ Check hft_session.json contains settings
4. ✅ Check bot code implements session check
5. ✅ Check logs for "trading session" messages

---

## 🔄 CHANGELOG

### v7.3.5
- ✅ Trading sessions fully persisted
- ✅ Auto-save on bot switch
- ✅ Auto-load on app start
- ✅ Support multiple bots with different sessions
- ✅ Deep copy to prevent config corruption

---

**Last Updated**: January 21, 2026  
**Version**: v7.3.5  
**Status**: ✅ FULLY IMPLEMENTED & TESTED
