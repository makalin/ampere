using Microsoft.UI.Xaml.Media;
using System;
using System.Collections.Generic;
using Windows.Storage;

namespace Ampere;

public enum AppTheme
{
    Light,
    Dark,
    HighContrast,
    Blue,
    Green,
    Purple
}

public class ThemeColors
{
    public SolidColorBrush Background { get; set; }
    public SolidColorBrush Surface { get; set; }
    public SolidColorBrush Primary { get; set; }
    public SolidColorBrush Secondary { get; set; }
    public SolidColorBrush Accent { get; set; }
    public SolidColorBrush TextPrimary { get; set; }
    public SolidColorBrush TextSecondary { get; set; }
    public SolidColorBrush Border { get; set; }
    public SolidColorBrush ControlBackground { get; set; }
    public SolidColorBrush ControlForeground { get; set; }
    public SolidColorBrush Success { get; set; }
    public SolidColorBrush Warning { get; set; }
    public SolidColorBrush Error { get; set; }
}

public class ThemeManager
{
    private static ThemeManager? _instance;
    public static ThemeManager Instance => _instance ??= new ThemeManager();

    private AppTheme _currentTheme = AppTheme.Dark;
    private const string ThemeKey = "AmpereSelectedTheme";

    public AppTheme CurrentTheme
    {
        get => _currentTheme;
        set
        {
            _currentTheme = value;
            SaveTheme();
            ApplyTheme();
        }
    }

    public ThemeColors GetColors()
    {
        return _currentTheme switch
        {
            AppTheme.Light => new ThemeColors
            {
                Background = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 242, 242, 242)),
                Surface = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 255, 255, 255)),
                Primary = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 0, 122, 199)),
                Secondary = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 128, 128, 128)),
                Accent = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 0, 166, 237)),
                TextPrimary = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 0, 0, 0)),
                TextSecondary = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 102, 102, 102)),
                Border = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 204, 204, 204)),
                ControlBackground = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 230, 230, 230)),
                ControlForeground = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 0, 0, 0)),
                Success = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 51, 179, 77)),
                Warning = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 255, 166, 0)),
                Error = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 230, 51, 51))
            },
            AppTheme.Dark => new ThemeColors
            {
                Background = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 28, 28, 31)),
                Surface = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 41, 41, 43)),
                Primary = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 0, 122, 199)),
                Secondary = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 128, 128, 128)),
                Accent = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 0, 166, 237)),
                TextPrimary = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 255, 255, 255)),
                TextSecondary = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 179, 179, 179)),
                Border = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 77, 77, 77)),
                ControlBackground = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 51, 51, 51)),
                ControlForeground = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 255, 255, 255)),
                Success = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 77, 204, 102)),
                Warning = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 255, 179, 51)),
                Error = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 255, 77, 77))
            },
            AppTheme.HighContrast => new ThemeColors
            {
                Background = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 0, 0, 0)),
                Surface = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 26, 26, 26)),
                Primary = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 255, 255, 255)),
                Secondary = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 204, 204, 204)),
                Accent = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 255, 255, 0)),
                TextPrimary = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 255, 255, 255)),
                TextSecondary = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 230, 230, 230)),
                Border = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 255, 255, 255)),
                ControlBackground = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 51, 51, 51)),
                ControlForeground = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 255, 255, 255)),
                Success = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 0, 255, 0)),
                Warning = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 255, 255, 0)),
                Error = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 255, 0, 0))
            },
            AppTheme.Blue => new ThemeColors
            {
                Background = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 20, 31, 46)),
                Surface = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 31, 46, 64)),
                Primary = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 51, 128, 230)),
                Secondary = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 102, 153, 204)),
                Accent = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 77, 179, 255)),
                TextPrimary = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 230, 243, 255)),
                TextSecondary = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 179, 204, 230)),
                Border = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 51, 77, 102)),
                ControlBackground = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 38, 56, 77)),
                ControlForeground = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 230, 243, 255)),
                Success = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 77, 204, 128)),
                Warning = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 255, 179, 77)),
                Error = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 255, 102, 102))
            },
            AppTheme.Green => new ThemeColors
            {
                Background = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 26, 38, 26)),
                Surface = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 38, 56, 38)),
                Primary = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 51, 179, 77)),
                Secondary = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 102, 153, 102)),
                Accent = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 77, 230, 102)),
                TextPrimary = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 243, 255, 243)),
                TextSecondary = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 204, 230, 204)),
                Border = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 51, 77, 51)),
                ControlBackground = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 46, 64, 46)),
                ControlForeground = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 243, 255, 243)),
                Success = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 77, 230, 102)),
                Warning = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 255, 179, 51)),
                Error = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 255, 77, 77))
            },
            AppTheme.Purple => new ThemeColors
            {
                Background = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 38, 26, 46)),
                Surface = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 51, 38, 56)),
                Primary = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 153, 77, 230)),
                Secondary = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 179, 128, 204)),
                Accent = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 204, 102, 255)),
                TextPrimary = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 255, 243, 255)),
                TextSecondary = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 230, 217, 230)),
                Border = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 77, 51, 89)),
                ControlBackground = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 56, 46, 64)),
                ControlForeground = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 255, 243, 255)),
                Success = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 102, 230, 128)),
                Warning = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 255, 179, 77)),
                Error = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 255, 77, 77))
            },
            _ => GetColors() // Fallback
        };
    }

    private ThemeManager()
    {
        LoadTheme();
        ApplyTheme();
    }

    private void ApplyTheme()
    {
        // Apply theme to application resources
        var colors = GetColors();
        // This would typically update Application.Resources
    }

    private void SaveTheme()
    {
        ApplicationData.Current.LocalSettings.Values[ThemeKey] = _currentTheme.ToString();
    }

    private void LoadTheme()
    {
        if (ApplicationData.Current.LocalSettings.Values.TryGetValue(ThemeKey, out var value) && value is string themeName)
        {
            if (Enum.TryParse<AppTheme>(themeName, out var theme))
            {
                _currentTheme = theme;
            }
        }
    }

    public List<AppTheme> GetAvailableThemes()
    {
        return new List<AppTheme> { AppTheme.Light, AppTheme.Dark, AppTheme.HighContrast, AppTheme.Blue, AppTheme.Green, AppTheme.Purple };
    }
}

