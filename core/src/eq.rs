// 10-band Equalizer implementation

use std::sync::{Arc, Mutex};
use uniffi::*;

/// 10-band EQ frequencies (Hz)
pub const EQ_BANDS: [f32; 10] = [
    31.0,    // Sub-bass
    62.0,    // Bass
    125.0,   // Low bass
    250.0,   // Low midrange
    500.0,   // Midrange
    1000.0,  // Upper midrange
    2000.0,  // Presence
    4000.0,  // Brilliance
    8000.0,  // High
    16000.0, // Ultra high
];

/// Equalizer with 10 bands
#[derive(Debug, Clone)]
pub struct Equalizer {
    bands: [f32; 10],
    enabled: bool,
}

impl Default for Equalizer {
    fn default() -> Self {
        Self {
            bands: [0.0; 10],
            enabled: true,
        }
    }
}

impl Equalizer {
    pub fn new() -> Self {
        Self::default()
    }

    /// Get gain for a specific band (-12.0 to +12.0 dB)
    pub fn get_band(&self, band: usize) -> f32 {
        if band < 10 {
            self.bands[band]
        } else {
            0.0
        }
    }

    /// Set gain for a specific band (-12.0 to +12.0 dB)
    pub fn set_band(&mut self, band: usize, gain: f32) -> Result<(), String> {
        if band >= 10 {
            return Err("Band index must be 0-9".to_string());
        }
        if gain < -12.0 || gain > 12.0 {
            return Err("Gain must be between -12.0 and +12.0 dB".to_string());
        }
        self.bands[band] = gain;
        Ok(())
    }

    /// Get all band gains
    pub fn get_all_bands(&self) -> Vec<f32> {
        self.bands.to_vec()
    }

    /// Set all band gains at once
    pub fn set_all_bands(&mut self, gains: Vec<f32>) -> Result<(), String> {
        if gains.len() != 10 {
            return Err("Must provide exactly 10 band gains".to_string());
        }
        for (i, &gain) in gains.iter().enumerate() {
            if gain < -12.0 || gain > 12.0 {
                return Err(format!("Gain {} at band {} is out of range", gain, i));
            }
        }
        self.bands = gains.try_into().unwrap();
        Ok(())
    }

    /// Reset all bands to 0.0
    pub fn reset(&mut self) {
        self.bands = [0.0; 10];
    }

    /// Enable or disable the equalizer
    pub fn set_enabled(&mut self, enabled: bool) {
        self.enabled = enabled;
    }

    /// Check if equalizer is enabled
    pub fn is_enabled(&self) -> bool {
        self.enabled
    }

    /// Apply EQ to a sample (simplified - real implementation would use IIR/FIR filters)
    pub fn process_sample(&self, sample: f32, _frequency: f32) -> f32 {
        if !self.enabled {
            return sample;
        }
        // Simplified: apply average gain
        // Real implementation would use proper filter design
        let avg_gain = self.bands.iter().sum::<f32>() / 10.0;
        let multiplier = 10.0_f32.powf(avg_gain / 20.0);
        sample * multiplier
    }
}

impl Equalizer {
    pub fn new_eq() -> Self {
        Self::new()
    }

    pub fn get_band_gain(&self, band: u8) -> Result<f32, AmpereError> {
        if band >= 10 {
            return Err(AmpereError::InvalidParameter {
                message: "Band index must be 0-9".to_string(),
            });
        }
        Ok(self.get_band(band as usize))
    }

    pub fn set_band_gain(&mut self, band: u8, gain: f32) -> Result<(), AmpereError> {
        self.set_band(band as usize, gain).map_err(|e| {
            AmpereError::InvalidParameter { message: e }
        })
    }

    pub fn get_all_band_gains(&self) -> Vec<f32> {
        self.get_all_bands()
    }

    pub fn set_all_band_gains(&mut self, gains: Vec<f32>) -> Result<(), AmpereError> {
        self.set_all_bands(gains).map_err(|e| {
            AmpereError::InvalidParameter { message: e }
        })
    }

    pub fn reset_eq(&mut self) {
        self.reset();
    }

    pub fn set_eq_enabled(&mut self, enabled: bool) {
        self.set_enabled(enabled);
    }

    pub fn is_eq_enabled(&self) -> bool {
        self.is_enabled()
    }
}

use crate::AmpereError;

