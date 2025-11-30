// Audio visualization and FFT

use std::sync::{Arc, Mutex};
use uniffi::*;

/// FFT analyzer for audio visualization
pub struct AudioVisualizer {
    fft_size: usize,
    sample_buffer: Arc<Mutex<Vec<f32>>>,
}

impl AudioVisualizer {
    pub fn new(fft_size: usize) -> Self {
        Self {
            fft_size,
            sample_buffer: Arc::new(Mutex::new(Vec::new())),
        }
    }

    /// Add audio samples for analysis
    pub fn add_samples(&self, samples: Vec<f32>) {
        let mut buffer = self.sample_buffer.lock().unwrap();
        buffer.extend_from_slice(&samples);
        // Keep buffer size reasonable
        let buffer_len = buffer.len();
        if buffer_len > self.fft_size * 4 {
            let drain_start = buffer_len - self.fft_size * 2;
            buffer.drain(0..drain_start);
        }
    }

    /// Get frequency spectrum (simplified - real implementation would use FFT)
    pub fn get_spectrum(&self, bands: usize) -> Vec<f32> {
        let buffer = self.sample_buffer.lock().unwrap();
        
        if buffer.is_empty() {
            return vec![0.0; bands];
        }

        // Simplified spectrum calculation
        // Real implementation would use rustfft for proper FFT
        let mut spectrum = vec![0.0; bands];
        let samples_per_band = (buffer.len() / bands).max(1);
        
        for (i, band) in spectrum.iter_mut().enumerate() {
            let start = i * samples_per_band;
            let end = ((i + 1) * samples_per_band).min(buffer.len());
            if start < buffer.len() {
                let sum: f32 = buffer[start..end].iter().map(|&s| s.abs()).sum();
                *band = sum / (end - start) as f32;
            }
        }

        // Normalize
        let max = spectrum.iter().copied().fold(0.0f32, f32::max);
        if max > 0.0 {
            for band in &mut spectrum {
                *band /= max;
            }
        }

        spectrum
    }

    /// Get waveform data
    pub fn get_waveform(&self, width: usize) -> Vec<f32> {
        let buffer = self.sample_buffer.lock().unwrap();
        
        if buffer.is_empty() {
            return vec![0.0; width];
        }

        let mut waveform = vec![0.0; width];
        let samples_per_pixel = (buffer.len() / width).max(1);

        for (i, pixel) in waveform.iter_mut().enumerate() {
            let start = i * samples_per_pixel;
            let end = ((i + 1) * samples_per_pixel).min(buffer.len());
            if start < buffer.len() {
                let sum: f32 = buffer[start..end].iter().map(|&s| s.abs()).sum();
                *pixel = sum / (end - start) as f32;
            }
        }

        waveform
    }

    /// Clear the sample buffer
    pub fn clear(&self) {
        self.sample_buffer.lock().unwrap().clear();
    }
}

impl AudioVisualizer {
    pub fn new_visualizer(fft_size: u32) -> Self {
        Self::new(fft_size as usize)
    }

    pub fn add_audio_samples(&self, samples: Vec<f32>) {
        self.add_samples(samples);
    }

    pub fn get_frequency_spectrum(&self, bands: u32) -> Vec<f32> {
        self.get_spectrum(bands as usize)
    }

    pub fn get_waveform_data(&self, width: u32) -> Vec<f32> {
        self.get_waveform(width as usize)
    }

    pub fn clear_visualizer(&self) {
        self.clear();
    }
}

