using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Windows.Storage.Pickers;
using Ampere.Bindings;

namespace Ampere;

public sealed partial class MainWindow : Window
{
    private AudioPlayer? player;
    private DispatcherTimer? stateTimer;

    public MainWindow()
    {
        this.InitializeComponent();
        InitializePlayer();
        StartStateTimer();
    }

    private void InitializePlayer()
    {
        try
        {
            player = AudioPlayer.New();
            VolumeSlider.Value = player.GetVolume();
            UpdateVolumeText();
        }
        catch (System.Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Failed to initialize audio player: {ex.Message}");
        }
    }

    private void StartStateTimer()
    {
        stateTimer = new DispatcherTimer();
        stateTimer.Interval = TimeSpan.FromMilliseconds(100);
        stateTimer.Tick += (s, e) => UpdateState();
        stateTimer.Start();
    }

    private void UpdateState()
    {
        if (player == null) return;

        try
        {
            var state = player.GetState();
            UpdateStateUI(state);

            if (player.IsFinished() && state == PlayerState.Playing)
            {
                UpdateStateUI(PlayerState.Stopped);
            }
        }
        catch (System.Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Error updating state: {ex.Message}");
        }
    }

    private void UpdateStateUI(PlayerState state)
    {
        // LED indicator: neon green = playing, amber = paused, dim = stopped
        var color = state switch
        {
            PlayerState.Playing => new SolidColorBrush(Windows.UI.Color.FromArgb(255, 0, 255, 65)),    // #00FF41
            PlayerState.Paused  => new SolidColorBrush(Windows.UI.Color.FromArgb(255, 255, 102, 0)),  // #FF6600
            _                   => new SolidColorBrush(Windows.UI.Color.FromArgb(255, 0, 80, 22))     // dim
        };
        StateIndicator.Fill = color;

        // Button symbol
        PlayPauseButton.Content = state == PlayerState.Playing ? "⏸" : "▶";

        // Update seek position
        if (player != null)
        {
            try
            {
                var pos      = player.GetPosition();
                var duration = player.GetDuration();
                if (duration > 0)
                {
                    PositionSlider.Value = pos / duration;
                    CurrentTimeText.Text = FormatTime(pos);
                    DurationText.Text    = FormatTime(duration);
                }
            }
            catch { }
        }
    }

    private static string FormatTime(double seconds)
    {
        var s = (int)seconds;
        return $"{s / 60}:{(s % 60):D2}";
    }

    private async void OpenFileButton_Click(object sender, RoutedEventArgs e)
    {
        var picker = new FileOpenPicker();
        var hwnd = WinRT.Interop.WindowNative.GetWindowHandle(this);
        WinRT.Interop.InitializeWithWindow.Initialize(picker, hwnd);
        
        picker.ViewMode = PickerViewMode.Thumbnail;
        picker.SuggestedStartLocation = PickerLocationId.MusicLibrary;
        picker.FileTypeFilter.Add(".mp3");
        picker.FileTypeFilter.Add(".wav");
        picker.FileTypeFilter.Add(".flac");
        picker.FileTypeFilter.Add(".ogg");
        picker.FileTypeFilter.Add(".aac");
        picker.FileTypeFilter.Add(".m4a");

        var file = await picker.PickSingleFileAsync();
        if (file != null && player != null)
        {
            try
            {
                player.LoadFile(file.Path);
                FileNameText.Text = file.Name;
                FilePathText.Text = file.Path;
            }
            catch (System.Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Failed to load file: {ex.Message}");
            }
        }
    }

    private void PlayPauseButton_Click(object sender, RoutedEventArgs e)
    {
        if (player == null) return;

        try
        {
            var state = player.GetState();
            if (state == PlayerState.Playing)
            {
                player.Pause();
            }
            else
            {
                player.Play();
            }
        }
        catch (System.Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Play/Pause error: {ex.Message}");
        }
    }

    private void StopButton_Click(object sender, RoutedEventArgs e)
    {
        if (player == null) return;

        try
        {
            player.Stop();
        }
        catch (System.Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Stop error: {ex.Message}");
        }
    }

    private void PrevButton_Click(object sender, RoutedEventArgs e)
    {
        // TODO: integrate with playlist previous track
        System.Diagnostics.Debug.WriteLine("Prev track");
    }

    private void NextButton_Click(object sender, RoutedEventArgs e)
    {
        // TODO: integrate with playlist next track
        System.Diagnostics.Debug.WriteLine("Next track");
    }

    private void PositionSlider_ValueChanged(object sender, Microsoft.UI.Xaml.Controls.Primitives.RangeBaseValueChangedEventArgs e)
    {
        if (player == null) return;
        try
        {
            var duration = player.GetDuration();
            if (duration > 0)
                player.Seek(e.NewValue * duration);
        }
        catch (System.Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Seek error: {ex.Message}");
        }
    }

    private void VolumeSlider_ValueChanged(object sender, Microsoft.UI.Xaml.Controls.Primitives.RangeBaseValueChangedEventArgs e)
    {
        if (player == null) return;

        try
        {
            player.SetVolume((float)e.NewValue);
            UpdateVolumeText();
        }
        catch (System.Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Volume error: {ex.Message}");
        }
    }

    private void UpdateVolumeText()
    {
        if (player == null) return;
        VolumeText.Text = $"{(int)(player.GetVolume() * 100)}%";
    }
}

