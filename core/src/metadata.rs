// Audio metadata extraction

use std::path::PathBuf;
use uniffi::*;
use serde::{Deserialize, Serialize};

/// Audio metadata
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AudioMetadata {
    pub title: Option<String>,
    pub artist: Option<String>,
    pub album: Option<String>,
    pub year: Option<u32>,
    pub genre: Option<String>,
    pub track_number: Option<u32>,
    pub duration: Option<u64>, // in seconds
    pub bitrate: Option<u32>,
    pub sample_rate: Option<u32>,
    pub channels: Option<u8>,
}

/// Metadata extractor
pub struct MetadataExtractor;

impl MetadataExtractor {
    pub fn new() -> Self {
        Self
    }

    /// Extract metadata from an audio file
    pub fn extract(path: String) -> Result<AudioMetadata, String> {
        let path_buf = PathBuf::from(&path);
        
        if !path_buf.exists() {
            return Err(format!("File does not exist: {}", path));
        }

        let extension = path_buf.extension()
            .and_then(|e| e.to_str())
            .unwrap_or("")
            .to_lowercase();

        match extension.as_str() {
            "mp3" => Self::extract_mp3(&path),
            "flac" => Self::extract_flac(&path),
            _ => Self::extract_basic(&path),
        }
    }

    fn extract_mp3(path: &str) -> Result<AudioMetadata, String> {
        use id3::TagLike;
        
        let tag = match id3::Tag::read_from_path(path) {
            Ok(tag) => tag,
            Err(_) => return Self::extract_basic(path),
        };

        Ok(AudioMetadata {
            title: tag.title().map(|s| s.to_string()),
            artist: tag.artist().map(|s| s.to_string()),
            album: tag.album().map(|s| s.to_string()),
            year: tag.year().map(|y| y as u32),
            genre: tag.genre().map(|g| g.to_string()),
            track_number: tag.track(),
            duration: None, // Would need to decode to get duration
            bitrate: None,
            sample_rate: None,
            channels: None,
        })
    }

    fn extract_flac(path: &str) -> Result<AudioMetadata, String> {
        use metaflac::Tag;
        
        let tag = match Tag::read_from_path(path) {
            Ok(tag) => tag,
            Err(_) => return Self::extract_basic(path),
        };

        let vorbis = tag.vorbis_comments();
        let streaminfo = tag.get_streaminfo();
        
        Ok(AudioMetadata {
            title: vorbis.as_ref().and_then(|v| v.title().and_then(|t| t.first().map(|s| s.clone()))),
            artist: vorbis.as_ref().and_then(|v| v.artist().and_then(|a| a.first().map(|s| s.clone()))),
            album: vorbis.as_ref().and_then(|v| v.album().and_then(|a| a.first().map(|s| s.clone()))),
            year: vorbis.as_ref().and_then(|v| {
                v.get("DATE")
                    .and_then(|d| d.first())
                    .and_then(|s| s.split('-').next())
                    .and_then(|s| s.parse::<u32>().ok())
            }),
            genre: vorbis.as_ref().and_then(|v| v.genre().and_then(|g| g.first().map(|s| s.clone()))),
            track_number: vorbis.as_ref().and_then(|v| v.track()),
            duration: None,
            bitrate: None,
            sample_rate: streaminfo.map(|si| si.sample_rate as u32),
            channels: None, // metaflac 0.2 doesn't expose channels directly
        })
    }

    fn extract_basic(path: &str) -> Result<AudioMetadata, String> {
        let path_buf = PathBuf::from(path);
        let file_name = path_buf.file_stem()
            .and_then(|s| s.to_str())
            .unwrap_or("Unknown")
            .to_string();

        Ok(AudioMetadata {
            title: Some(file_name),
            artist: None,
            album: None,
            year: None,
            genre: None,
            track_number: None,
            duration: None,
            bitrate: None,
            sample_rate: None,
            channels: None,
        })
    }
}

impl MetadataExtractor {
    pub fn new_extractor() -> Self {
        Self::new()
    }

    pub fn extract_metadata(&self, path: String) -> Result<AudioMetadata, AmpereError> {
        Self::extract(path).map_err(|e| AmpereError::FileError {
            message: e,
        })
    }
}

use crate::AmpereError;

