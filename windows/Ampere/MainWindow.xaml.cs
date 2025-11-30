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
        StateText.Text = state.ToString();
        
        var color = state switch
        {
            PlayerState.Playing => new SolidColorBrush(Microsoft.UI.Colors.Green),
            PlayerState.Paused => new SolidColorBrush(Microsoft.UI.Colors.Orange),
            _ => new SolidColorBrush(Microsoft.UI.Colors.Gray)
        };
        
        StateIndicator.Fill = color;
        
        PlayPauseButton.Content = state == PlayerState.Playing ? "Pause" : "Play";
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

