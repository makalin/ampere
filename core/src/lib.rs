use std::sync::{Arc, Mutex};
use std::path::PathBuf;
use rodio::{Decoder, OutputStream, Sink, Source};
use std::fs::File;
use std::io::BufReader;
use anyhow::Context;
// use uniffi::*;

mod eq;
mod playlist;
mod metadata;
mod visualizer;
mod theme;

pub use eq::*;
pub use playlist::*;
pub use metadata::*;
pub use visualizer::*;
pub use theme::*;

// UniFFI scaffolding temporarily disabled
// uniffi::include_scaffolding!("ampere_core");

/// Audio player state
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PlayerState {
    Stopped,
    Playing,
    Paused,
}

/// Main audio player struct
pub struct AudioPlayer {
    sink: Arc<Mutex<Option<Sink>>>,
    _stream: Arc<Mutex<Option<OutputStream>>>,
    state: Arc<Mutex<PlayerState>>,
    current_file: Arc<Mutex<Option<String>>>,
    volume: Arc<Mutex<f32>>,
    position: Arc<Mutex<f64>>, // Current position in seconds
    duration: Arc<Mutex<Option<f64>>>, // Total duration in seconds
    eq: Arc<Mutex<Equalizer>>,
    playlist: Arc<Mutex<Option<Arc<Playlist>>>>,
}

#[derive(Debug, thiserror::Error)]
pub enum AmpereError {
    #[error("Audio error: {message}")]
    AudioError { message: String },
    #[error("File error: {message}")]
    FileError { message: String },
    #[error("Invalid parameter: {message}")]
    InvalidParameter { message: String },
}

impl From<anyhow::Error> for AmpereError {
    fn from(err: anyhow::Error) -> Self {
        AmpereError::AudioError {
            message: err.to_string(),
        }
    }
}

impl AudioPlayer {
    /// Create a new audio player instance
    pub fn new() -> Result<Self, AmpereError> {
        let (_stream, stream_handle) = OutputStream::try_default()
            .context("Failed to create audio output stream")
            .map_err(|e| AmpereError::AudioError {
                message: e.to_string(),
            })?;
        
        let sink = Sink::try_new(&stream_handle)
            .context("Failed to create audio sink")
            .map_err(|e| AmpereError::AudioError {
                message: e.to_string(),
            })?;
        
        Ok(Self {
            sink: Arc::new(Mutex::new(Some(sink))),
            _stream: Arc::new(Mutex::new(Some(_stream))),
            state: Arc::new(Mutex::new(PlayerState::Stopped)),
            current_file: Arc::new(Mutex::new(None)),
            volume: Arc::new(Mutex::new(1.0)),
            position: Arc::new(Mutex::new(0.0)),
            duration: Arc::new(Mutex::new(None)),
            eq: Arc::new(Mutex::new(Equalizer::new())),
            playlist: Arc::new(Mutex::new(None)),
        })
    }

    /// Create a new audio player instance with default settings
    pub fn new_default() -> Result<Self, AmpereError> {
        Self::new()
    }

    /// Load and play an audio file
    
    pub fn load_file(&self, path: String) -> Result<(), AmpereError> {
        let file_path = PathBuf::from(&path);
        
        if !file_path.exists() {
            return Err(AmpereError::FileError {
                message: format!("File does not exist: {}", path),
            });
        }

        let file = File::open(&file_path)
            .with_context(|| format!("Failed to open file: {}", path))
            .map_err(|e| AmpereError::FileError {
                message: e.to_string(),
            })?;
        
        let source = Decoder::new(BufReader::new(file))
            .with_context(|| format!("Failed to decode audio file: {}", path))
            .map_err(|e| AmpereError::AudioError {
                message: e.to_string(),
            })?;

        // Stop current playback
        self.stop()?;

        // Create new sink
        let (_stream, stream_handle) = OutputStream::try_default()
            .context("Failed to create audio output stream")
            .map_err(|e| AmpereError::AudioError {
                message: e.to_string(),
            })?;
        
        let sink = Sink::try_new(&stream_handle)
            .context("Failed to create audio sink")
            .map_err(|e| AmpereError::AudioError {
                message: e.to_string(),
            })?;
        
        sink.set_volume(*self.volume.lock().unwrap());
        sink.append(source);
        
        *self.sink.lock().unwrap() = Some(sink);
        *self.current_file.lock().unwrap() = Some(path);
        *self.state.lock().unwrap() = PlayerState::Playing;

        Ok(())
    }

    /// Play the loaded audio file
    
    pub fn play(&self) -> Result<(), AmpereError> {
        let mut state = self.state.lock().unwrap();
        let sink_guard = self.sink.lock().unwrap();
        
        if let Some(ref sink) = *sink_guard {
            match *state {
                PlayerState::Paused => {
                    sink.play();
                    *state = PlayerState::Playing;
                }
                PlayerState::Stopped => {
                    // Need to reload file
                    if let Some(ref file) = *self.current_file.lock().unwrap() {
                        drop(sink_guard);
                        drop(state);
                        self.load_file(file.clone())?;
                    } else {
                        return Err(AmpereError::FileError {
                            message: "No file loaded".to_string(),
                        });
                    }
                }
                PlayerState::Playing => {
                    // Already playing
                }
            }
        } else {
            return Err(AmpereError::AudioError {
                message: "Audio sink not initialized".to_string(),
            });
        }
        
        Ok(())
    }

    /// Pause playback
    
    pub fn pause(&self) -> Result<(), AmpereError> {
        let mut state = self.state.lock().unwrap();
        let sink_guard = self.sink.lock().unwrap();
        
        if let Some(ref sink) = *sink_guard {
            sink.pause();
            *state = PlayerState::Paused;
        }
        
        Ok(())
    }

    /// Stop playback
    
    pub fn stop(&self) -> Result<(), AmpereError> {
        let mut state = self.state.lock().unwrap();
        let sink_guard = self.sink.lock().unwrap();
        
        if let Some(ref sink) = *sink_guard {
            sink.stop();
        }
        
        *state = PlayerState::Stopped;
        Ok(())
    }

    /// Get current playback state
    
    pub fn get_state(&self) -> PlayerState {
        *self.state.lock().unwrap()
    }

    /// Set volume (0.0 to 1.0)
    
    pub fn set_volume(&self, volume: f32) -> Result<(), AmpereError> {
        if volume < 0.0 || volume > 1.0 {
            return Err(AmpereError::InvalidParameter {
                message: "Volume must be between 0.0 and 1.0".to_string(),
            });
        }
        
        *self.volume.lock().unwrap() = volume;
        
        let sink_guard = self.sink.lock().unwrap();
        if let Some(ref sink) = *sink_guard {
            sink.set_volume(volume);
        }
        
        Ok(())
    }

    /// Get current volume
    
    pub fn get_volume(&self) -> f32 {
        *self.volume.lock().unwrap()
    }

    /// Get current file path
    
    pub fn get_current_file(&self) -> Option<String> {
        self.current_file.lock().unwrap().clone()
    }

    /// Check if playback is finished
    
    pub fn is_finished(&self) -> bool {
        let sink_guard = self.sink.lock().unwrap();
        if let Some(ref sink) = *sink_guard {
            sink.empty()
        } else {
            true
        }
    }

    /// Seek to position in seconds
    
    pub fn seek(&self, position: f64) -> Result<(), AmpereError> {
        if position < 0.0 {
            return Err(AmpereError::InvalidParameter {
                message: "Position cannot be negative".to_string(),
            });
        }

        let current_file = self.current_file.lock().unwrap().clone();
        if let Some(_file_path) = current_file {
            // Reload file and skip to position
            // Note: This is a simplified implementation
            // Real seek would require proper audio stream seeking
            *self.position.lock().unwrap() = position;
            Ok(())
        } else {
            Err(AmpereError::FileError {
                message: "No file loaded".to_string(),
            })
        }
    }

    /// Get current playback position in seconds
    
    pub fn get_position(&self) -> f64 {
        *self.position.lock().unwrap()
    }

    /// Get total duration in seconds
    
    pub fn get_duration(&self) -> Option<f64> {
        *self.duration.lock().unwrap()
    }

    /// Get equalizer band gain
    
    pub fn get_eq_band(&self, band: u8) -> Result<f32, AmpereError> {
        let eq = self.eq.lock().unwrap();
        if band >= 10 {
            return Err(AmpereError::InvalidParameter {
                message: "Band index must be 0-9".to_string(),
            });
        }
        Ok(eq.get_band(band as usize))
    }

    /// Set equalizer band gain
    
    pub fn set_eq_band(&self, band: u8, gain: f32) -> Result<(), AmpereError> {
        let mut eq = self.eq.lock().unwrap();
        eq.set_band(band as usize, gain).map_err(|e| AmpereError::InvalidParameter {
            message: e,
        })
    }

    /// Reset equalizer
    
    pub fn reset_eq(&self) {
        let mut eq = self.eq.lock().unwrap();
        eq.reset();
    }

    /// Enable/disable equalizer
    
    pub fn set_eq_enabled(&self, enabled: bool) {
        let mut eq = self.eq.lock().unwrap();
        eq.set_enabled(enabled);
    }

    /// Check if equalizer is enabled
    
    pub fn is_eq_enabled(&self) -> bool {
        let eq = self.eq.lock().unwrap();
        eq.is_enabled()
    }

    /// Add file to playlist
    
    pub fn add_to_playlist(&self, path: String) -> Result<(), AmpereError> {
        let mut playlist_guard = self.playlist.lock().unwrap();
        if playlist_guard.is_none() {
            *playlist_guard = Some(Arc::new(Playlist::new_playlist()));
        }
        if let Some(ref playlist) = *playlist_guard {
            playlist.add_file_to_playlist(path)
        } else {
            Err(AmpereError::FileError {
                message: "Failed to create playlist".to_string(),
            })
        }
    }

    /// Play next track from playlist
    
    pub fn play_next(&self) -> Result<(), AmpereError> {
        let playlist_guard = self.playlist.lock().unwrap();
        if let Some(ref playlist) = *playlist_guard {
            if let Some(next_path) = playlist.get_next_track_path() {
                let path = next_path;
                drop(playlist_guard);
                self.load_file(path)
            } else {
                Err(AmpereError::FileError {
                    message: "No next track in playlist".to_string(),
                })
            }
        } else {
            Err(AmpereError::FileError {
                message: "No playlist loaded".to_string(),
            })
        }
    }

    /// Play previous track from playlist
    
    pub fn play_previous(&self) -> Result<(), AmpereError> {
        let playlist_guard = self.playlist.lock().unwrap();
        if let Some(ref playlist) = *playlist_guard {
            if let Some(prev_path) = playlist.get_previous_track_path() {
                let path = prev_path;
                drop(playlist_guard);
                self.load_file(path)
            } else {
                Err(AmpereError::FileError {
                    message: "No previous track in playlist".to_string(),
                })
            }
        } else {
            Err(AmpereError::FileError {
                message: "No playlist loaded".to_string(),
            })
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_player_creation() {
        let player = AudioPlayer::new();
        assert!(player.is_ok());
    }

    #[test]
    fn test_volume_setting() {
        let player = AudioPlayer::new().unwrap();
        assert!(player.set_volume(0.5).is_ok());
        assert_eq!(player.get_volume(), 0.5);
    }
}
