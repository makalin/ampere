// Theme system for Ampere

use serde::{Deserialize, Serialize};
use uniffi::*;

/// Color in RGBA format (0.0 to 1.0)
#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub struct Color {
    pub r: f32,
    pub g: f32,
    pub b: f32,
    pub a: f32,
}

impl Color {
    pub fn new(r: f32, g: f32, b: f32, a: f32) -> Self {
        Self { r, g, b, a }
    }

    pub fn rgb(r: f32, g: f32, b: f32) -> Self {
        Self { r, g, b, a: 1.0 }
    }

    pub fn from_hex(hex: u32) -> Self {
        let r = ((hex >> 16) & 0xFF) as f32 / 255.0;
        let g = ((hex >> 8) & 0xFF) as f32 / 255.0;
        let b = (hex & 0xFF) as f32 / 255.0;
        Self { r, g, b, a: 1.0 }
    }
}

/// Theme definition
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Theme {
    pub name: String,
    pub background: Color,
    pub surface: Color,
    pub primary: Color,
    pub secondary: Color,
    pub accent: Color,
    pub text_primary: Color,
    pub text_secondary: Color,
    pub border: Color,
    pub control_background: Color,
    pub control_foreground: Color,
    pub success: Color,
    pub warning: Color,
    pub error: Color,
}

/// Theme manager
pub struct ThemeManager {
    current_theme: Arc<Mutex<Theme>>,
    available_themes: Arc<Mutex<Vec<Theme>>>,
}

impl ThemeManager {
    pub fn new() -> Self {
        let mut manager = Self {
            current_theme: Arc::new(Mutex::new(Self::default_theme())),
            available_themes: Arc::new(Mutex::new(Vec::new())),
        };
        
        // Initialize with built-in themes
        manager.initialize_themes();
        manager
    }

    fn initialize_themes(&mut self) {
        let mut themes = self.available_themes.lock().unwrap();
        themes.push(Self::light_theme());
        themes.push(Self::dark_theme());
        themes.push(Self::high_contrast_theme());
        themes.push(Self::blue_theme());
        themes.push(Self::green_theme());
        themes.push(Self::purple_theme());
    }

    /// Get current theme
    pub fn get_current_theme(&self) -> Theme {
        self.current_theme.lock().unwrap().clone()
    }

    /// Set current theme by name
    pub fn set_theme(&self, name: String) -> Result<(), String> {
        let themes = self.available_themes.lock().unwrap();
        if let Some(theme) = themes.iter().find(|t| t.name == name) {
            *self.current_theme.lock().unwrap() = theme.clone();
            Ok(())
        } else {
            Err(format!("Theme '{}' not found", name))
        }
    }

    /// Get all available themes
    pub fn get_available_themes(&self) -> Vec<Theme> {
        self.available_themes.lock().unwrap().clone()
    }

    /// Add a custom theme
    pub fn add_theme(&self, theme: Theme) {
        let mut themes = self.available_themes.lock().unwrap();
        // Remove existing theme with same name if present
        themes.retain(|t| t.name != theme.name);
        themes.push(theme);
    }

    /// Save theme to file
    pub fn save_theme(&self, theme: Theme, path: String) -> Result<(), String> {
        let json = serde_json::to_string_pretty(&theme)
            .map_err(|e| format!("Failed to serialize theme: {}", e))?;
        std::fs::write(&path, json)
            .map_err(|e| format!("Failed to write theme file: {}", e))?;
        Ok(())
    }

    /// Load theme from file
    pub fn load_theme(&self, path: String) -> Result<Theme, String> {
        let content = std::fs::read_to_string(&path)
            .map_err(|e| format!("Failed to read theme file: {}", e))?;
        let theme: Theme = serde_json::from_str(&content)
            .map_err(|e| format!("Failed to parse theme: {}", e))?;
        Ok(theme)
    }

    // Built-in themes

    fn default_theme() -> Theme {
        Self::dark_theme()
    }

    pub fn light_theme() -> Theme {
        Theme {
            name: "Light".to_string(),
            background: Color::rgb(0.95, 0.95, 0.95),
            surface: Color::rgb(1.0, 1.0, 1.0),
            primary: Color::rgb(0.0, 0.48, 0.78),
            secondary: Color::rgb(0.5, 0.5, 0.5),
            accent: Color::rgb(0.0, 0.65, 0.93),
            text_primary: Color::rgb(0.0, 0.0, 0.0),
            text_secondary: Color::rgb(0.4, 0.4, 0.4),
            border: Color::rgb(0.8, 0.8, 0.8),
            control_background: Color::rgb(0.9, 0.9, 0.9),
            control_foreground: Color::rgb(0.0, 0.0, 0.0),
            success: Color::rgb(0.2, 0.7, 0.3),
            warning: Color::rgb(1.0, 0.65, 0.0),
            error: Color::rgb(0.9, 0.2, 0.2),
        }
    }

    pub fn dark_theme() -> Theme {
        Theme {
            name: "Dark".to_string(),
            background: Color::rgb(0.11, 0.11, 0.12),
            surface: Color::rgb(0.16, 0.16, 0.17),
            primary: Color::rgb(0.0, 0.48, 0.78),
            secondary: Color::rgb(0.5, 0.5, 0.5),
            accent: Color::rgb(0.0, 0.65, 0.93),
            text_primary: Color::rgb(1.0, 1.0, 1.0),
            text_secondary: Color::rgb(0.7, 0.7, 0.7),
            border: Color::rgb(0.3, 0.3, 0.3),
            control_background: Color::rgb(0.2, 0.2, 0.2),
            control_foreground: Color::rgb(1.0, 1.0, 1.0),
            success: Color::rgb(0.3, 0.8, 0.4),
            warning: Color::rgb(1.0, 0.7, 0.2),
            error: Color::rgb(1.0, 0.3, 0.3),
        }
    }

    pub fn high_contrast_theme() -> Theme {
        Theme {
            name: "High Contrast".to_string(),
            background: Color::rgb(0.0, 0.0, 0.0),
            surface: Color::rgb(0.1, 0.1, 0.1),
            primary: Color::rgb(1.0, 1.0, 1.0),
            secondary: Color::rgb(0.8, 0.8, 0.8),
            accent: Color::rgb(1.0, 1.0, 0.0),
            text_primary: Color::rgb(1.0, 1.0, 1.0),
            text_secondary: Color::rgb(0.9, 0.9, 0.9),
            border: Color::rgb(1.0, 1.0, 1.0),
            control_background: Color::rgb(0.2, 0.2, 0.2),
            control_foreground: Color::rgb(1.0, 1.0, 1.0),
            success: Color::rgb(0.0, 1.0, 0.0),
            warning: Color::rgb(1.0, 1.0, 0.0),
            error: Color::rgb(1.0, 0.0, 0.0),
        }
    }

    pub fn blue_theme() -> Theme {
        Theme {
            name: "Blue".to_string(),
            background: Color::rgb(0.08, 0.12, 0.18),
            surface: Color::rgb(0.12, 0.18, 0.25),
            primary: Color::rgb(0.2, 0.5, 0.9),
            secondary: Color::rgb(0.4, 0.6, 0.8),
            accent: Color::rgb(0.3, 0.7, 1.0),
            text_primary: Color::rgb(0.9, 0.95, 1.0),
            text_secondary: Color::rgb(0.7, 0.8, 0.9),
            border: Color::rgb(0.2, 0.3, 0.4),
            control_background: Color::rgb(0.15, 0.22, 0.3),
            control_foreground: Color::rgb(0.9, 0.95, 1.0),
            success: Color::rgb(0.3, 0.8, 0.5),
            warning: Color::rgb(1.0, 0.7, 0.3),
            error: Color::rgb(1.0, 0.4, 0.4),
        }
    }

    pub fn green_theme() -> Theme {
        Theme {
            name: "Green".to_string(),
            background: Color::rgb(0.1, 0.15, 0.1),
            surface: Color::rgb(0.15, 0.22, 0.15),
            primary: Color::rgb(0.2, 0.7, 0.3),
            secondary: Color::rgb(0.4, 0.6, 0.4),
            accent: Color::rgb(0.3, 0.9, 0.4),
            text_primary: Color::rgb(0.95, 1.0, 0.95),
            text_secondary: Color::rgb(0.8, 0.9, 0.8),
            border: Color::rgb(0.2, 0.3, 0.2),
            control_background: Color::rgb(0.18, 0.25, 0.18),
            control_foreground: Color::rgb(0.95, 1.0, 0.95),
            success: Color::rgb(0.3, 0.9, 0.4),
            warning: Color::rgb(1.0, 0.7, 0.2),
            error: Color::rgb(1.0, 0.3, 0.3),
        }
    }

    pub fn purple_theme() -> Theme {
        Theme {
            name: "Purple".to_string(),
            background: Color::rgb(0.15, 0.1, 0.18),
            surface: Color::rgb(0.2, 0.15, 0.22),
            primary: Color::rgb(0.6, 0.3, 0.9),
            secondary: Color::rgb(0.7, 0.5, 0.8),
            accent: Color::rgb(0.8, 0.4, 1.0),
            text_primary: Color::rgb(1.0, 0.95, 1.0),
            text_secondary: Color::rgb(0.9, 0.85, 0.9),
            border: Color::rgb(0.3, 0.2, 0.35),
            control_background: Color::rgb(0.22, 0.18, 0.25),
            control_foreground: Color::rgb(1.0, 0.95, 1.0),
            success: Color::rgb(0.4, 0.9, 0.5),
            warning: Color::rgb(1.0, 0.7, 0.3),
            error: Color::rgb(1.0, 0.3, 0.3),
        }
    }
}

use std::sync::{Arc, Mutex};
use crate::AmpereError;

impl ThemeManager {
    pub fn new_manager() -> Self {
        Self::new()
    }

    pub fn get_current(&self) -> Theme {
        self.get_current_theme()
    }

    pub fn set_theme_by_name(&self, name: String) -> Result<(), AmpereError> {
        self.set_theme(name).map_err(|e| AmpereError::InvalidParameter {
            message: e,
        })
    }

    pub fn get_available(&self) -> Vec<Theme> {
        self.get_available_themes()
    }

    pub fn add_custom_theme(&self, theme: Theme) {
        self.add_theme(theme);
    }

    pub fn save_theme_to_file(&self, theme: Theme, path: String) -> Result<(), AmpereError> {
        self.save_theme(theme, path).map_err(|e| AmpereError::FileError {
            message: e,
        })
    }

    pub fn load_theme_from_file(&self, path: String) -> Result<Theme, AmpereError> {
        self.load_theme(path).map_err(|e| AmpereError::FileError {
            message: e,
        })
    }
}

