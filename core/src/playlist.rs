// Playlist management

use std::sync::{Arc, Mutex};
use std::path::PathBuf;
use serde::{Deserialize, Serialize};
use uniffi::*;
use indexmap::IndexMap;

/// Playlist entry
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlaylistEntry {
    pub path: String,
    pub title: Option<String>,
    pub artist: Option<String>,
    pub album: Option<String>,
    pub duration: Option<u64>, // in seconds
}

/// Playlist with repeat and shuffle modes
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum RepeatMode {
    None,
    One,
    All,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ShuffleMode {
    Off,
    On,
}

/// Playlist manager
#[derive(Debug, Clone)]
pub struct Playlist {
    entries: Arc<Mutex<Vec<PlaylistEntry>>>,
    current_index: Arc<Mutex<Option<usize>>>,
    shuffle_order: Arc<Mutex<Vec<usize>>>,
    repeat_mode: Arc<Mutex<RepeatMode>>,
    shuffle_mode: Arc<Mutex<ShuffleMode>>,
}

impl Playlist {
    pub fn new() -> Self {
        Self {
            entries: Arc::new(Mutex::new(Vec::new())),
            current_index: Arc::new(Mutex::new(None)),
            shuffle_order: Arc::new(Mutex::new(Vec::new())),
            repeat_mode: Arc::new(Mutex::new(RepeatMode::None)),
            shuffle_mode: Arc::new(Mutex::new(ShuffleMode::Off)),
        }
    }

    /// Add a file to the playlist
    pub fn add_file(&self, path: String) -> Result<(), String> {
        let path_buf = PathBuf::from(&path);
        if !path_buf.exists() {
            return Err(format!("File does not exist: {}", path));
        }

        let entry = PlaylistEntry {
            path,
            title: None,
            artist: None,
            album: None,
            duration: None,
        };

        self.entries.lock().unwrap().push(entry);
        self.rebuild_shuffle_order();
        Ok(())
    }

    /// Remove a file from the playlist
    pub fn remove_file(&self, index: usize) -> Result<(), String> {
        let mut entries = self.entries.lock().unwrap();
        if index >= entries.len() {
            return Err("Index out of range".to_string());
        }
        entries.remove(index);
        self.rebuild_shuffle_order();
        Ok(())
    }

    /// Clear the playlist
    pub fn clear(&self) {
        self.entries.lock().unwrap().clear();
        *self.current_index.lock().unwrap() = None;
        self.shuffle_order.lock().unwrap().clear();
    }

    /// Get current track index
    pub fn get_current_index(&self) -> Option<usize> {
        *self.current_index.lock().unwrap()
    }

    /// Set current track index
    pub fn set_current_index(&self, index: usize) -> Result<(), String> {
        let entries = self.entries.lock().unwrap();
        if index >= entries.len() {
            return Err("Index out of range".to_string());
        }
        *self.current_index.lock().unwrap() = Some(index);
        Ok(())
    }

    /// Get current track
    pub fn get_current_track(&self) -> Option<PlaylistEntry> {
        let index = match *self.current_index.lock().unwrap() {
            Some(idx) => idx,
            None => return None,
        };
        let entries = self.entries.lock().unwrap();
        entries.get(index).cloned()
    }

    /// Get next track
    pub fn get_next_track(&self) -> Option<PlaylistEntry> {
        let entries = self.entries.lock().unwrap();
        if entries.is_empty() {
            return None;
        }

        let shuffle = *self.shuffle_mode.lock().unwrap() == ShuffleMode::On;
        let repeat = *self.repeat_mode.lock().unwrap();

        let next_index = if shuffle {
            let shuffle_order = self.shuffle_order.lock().unwrap();
            let current = match *self.current_index.lock().unwrap() {
                Some(idx) => idx,
                None => return None,
            };
            let pos = match shuffle_order.iter().position(|&i| i == current) {
                Some(p) => p,
                None => return None,
            };
            if pos + 1 < shuffle_order.len() {
                Some(shuffle_order[pos + 1])
            } else if repeat == RepeatMode::All {
                Some(shuffle_order[0])
            } else {
                None
            }
        } else {
            let current = match *self.current_index.lock().unwrap() {
                Some(idx) => idx,
                None => return None,
            };
            if current + 1 < entries.len() {
                Some(current + 1)
            } else if repeat == RepeatMode::All {
                Some(0)
            } else {
                None
            }
        };

        if let Some(idx) = next_index {
            *self.current_index.lock().unwrap() = Some(idx);
            entries.get(idx).cloned()
        } else {
            None
        }
    }

    /// Get previous track
    pub fn get_previous_track(&self) -> Option<PlaylistEntry> {
        let entries = self.entries.lock().unwrap();
        if entries.is_empty() {
            return None;
        }

        let shuffle = *self.shuffle_mode.lock().unwrap() == ShuffleMode::On;
        let current = match *self.current_index.lock().unwrap() {
            Some(idx) => idx,
            None => return None,
        };

        let prev_index = if shuffle {
            let shuffle_order = self.shuffle_order.lock().unwrap();
            let pos = match shuffle_order.iter().position(|&i| i == current) {
                Some(p) => p,
                None => return None,
            };
            if pos > 0 {
                Some(shuffle_order[pos - 1])
            } else if *self.repeat_mode.lock().unwrap() == RepeatMode::All {
                Some(*shuffle_order.last().unwrap())
            } else {
                None
            }
        } else {
            if current > 0 {
                Some(current - 1)
            } else if *self.repeat_mode.lock().unwrap() == RepeatMode::All {
                Some(entries.len() - 1)
            } else {
                None
            }
        };

        if let Some(idx) = prev_index {
            *self.current_index.lock().unwrap() = Some(idx);
            entries.get(idx).cloned()
        } else {
            None
        }
    }

    /// Get all entries
    pub fn get_entries(&self) -> Vec<PlaylistEntry> {
        self.entries.lock().unwrap().clone()
    }

    /// Get entry count
    pub fn len(&self) -> usize {
        self.entries.lock().unwrap().len()
    }

    /// Check if playlist is empty
    pub fn is_empty(&self) -> bool {
        self.entries.lock().unwrap().is_empty()
    }

    /// Set repeat mode
    pub fn set_repeat_mode(&self, mode: RepeatMode) {
        *self.repeat_mode.lock().unwrap() = mode;
    }

    /// Get repeat mode
    pub fn get_repeat_mode(&self) -> RepeatMode {
        *self.repeat_mode.lock().unwrap()
    }

    /// Set shuffle mode
    pub fn set_shuffle_mode(&self, mode: ShuffleMode) {
        *self.shuffle_mode.lock().unwrap() = mode;
        self.rebuild_shuffle_order();
    }

    /// Get shuffle mode
    pub fn get_shuffle_mode(&self) -> ShuffleMode {
        *self.shuffle_mode.lock().unwrap()
    }

    /// Rebuild shuffle order
    fn rebuild_shuffle_order(&self) {
        let entries = self.entries.lock().unwrap();
        let mut order: Vec<usize> = (0..entries.len()).collect();
        // Simple shuffle (Fisher-Yates would be better)
        use std::collections::hash_map::DefaultHasher;
        use std::hash::{Hash, Hasher};
        let mut hasher = DefaultHasher::new();
        entries.len().hash(&mut hasher);
        // Simple pseudo-random shuffle based on length
        for i in 0..order.len() {
            let j = (i + entries.len() / 3) % order.len();
            order.swap(i, j);
        }
        *self.shuffle_order.lock().unwrap() = order;
    }

    /// Save playlist to JSON
    pub fn save_to_json(&self, path: String) -> Result<(), String> {
        let entries = self.entries.lock().unwrap();
        let json = serde_json::to_string_pretty(&*entries)
            .map_err(|e| format!("Failed to serialize: {}", e))?;
        std::fs::write(&path, json)
            .map_err(|e| format!("Failed to write file: {}", e))?;
        Ok(())
    }

    /// Load playlist from JSON
    pub fn load_from_json(&self, path: String) -> Result<(), String> {
        let content = std::fs::read_to_string(&path)
            .map_err(|e| format!("Failed to read file: {}", e))?;
        let entries: Vec<PlaylistEntry> = serde_json::from_str(&content)
            .map_err(|e| format!("Failed to parse JSON: {}", e))?;
        *self.entries.lock().unwrap() = entries;
        self.rebuild_shuffle_order();
        Ok(())
    }
}

impl Playlist {
    pub fn new_playlist() -> Self {
        Self::new()
    }

    pub fn add_file_to_playlist(&self, path: String) -> Result<(), AmpereError> {
        self.add_file(path).map_err(|e| AmpereError::FileError {
            message: e,
        })
    }

    pub fn remove_file_from_playlist(&self, index: u32) -> Result<(), AmpereError> {
        self.remove_file(index as usize).map_err(|e| AmpereError::FileError {
            message: e,
        })
    }

    pub fn clear_playlist(&self) {
        self.clear();
    }

    pub fn get_current_track_index(&self) -> Option<u32> {
        self.get_current_index().map(|i| i as u32)
    }

    pub fn set_current_track_index(&self, index: u32) -> Result<(), AmpereError> {
        self.set_current_index(index as usize).map_err(|e| AmpereError::InvalidParameter {
            message: e,
        })
    }

    pub fn get_current_track_path(&self) -> Option<String> {
        self.get_current_track().map(|e| e.path)
    }

    pub fn get_next_track_path(&self) -> Option<String> {
        self.get_next_track().map(|e| e.path)
    }

    pub fn get_previous_track_path(&self) -> Option<String> {
        self.get_previous_track().map(|e| e.path)
    }

    pub fn get_playlist_length(&self) -> u32 {
        self.len() as u32
    }

    pub fn is_playlist_empty(&self) -> bool {
        self.is_empty()
    }

    pub fn set_repeat(&self, mode: RepeatMode) {
        self.set_repeat_mode(mode);
    }

    pub fn get_repeat(&self) -> RepeatMode {
        self.get_repeat_mode()
    }

    pub fn set_shuffle(&self, mode: ShuffleMode) {
        self.set_shuffle_mode(mode);
    }

    pub fn get_shuffle(&self) -> ShuffleMode {
        self.get_shuffle_mode()
    }

    pub fn save_playlist(&self, path: String) -> Result<(), AmpereError> {
        self.save_to_json(path).map_err(|e| AmpereError::FileError {
            message: e,
        })
    }

    pub fn load_playlist(&self, path: String) -> Result<(), AmpereError> {
        self.load_from_json(path).map_err(|e| AmpereError::FileError {
            message: e,
        })
    }
}

use crate::AmpereError;

