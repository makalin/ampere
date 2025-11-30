#[cfg(test)]
mod integration_tests {
    use ampere_core::AudioPlayer;
    
    #[test]
    fn test_player_creation() {
        let player = AudioPlayer::new();
        assert!(player.is_ok());
    }
    
    #[test]
    fn test_volume_control() {
        let player = AudioPlayer::new().unwrap();
        
        // Test setting volume
        assert!(player.set_volume(0.5).is_ok());
        assert_eq!(player.get_volume(), 0.5);
        
        // Test invalid volume
        assert!(player.set_volume(1.5).is_err());
        assert!(player.set_volume(-0.1).is_err());
    }
    
    #[test]
    fn test_state_management() {
        let player = AudioPlayer::new().unwrap();
        
        // Initial state should be stopped
        assert_eq!(player.get_state(), ampere_core::PlayerState::Stopped);
        
        // Test stop (should not error even when already stopped)
        assert!(player.stop().is_ok());
    }
    
    #[test]
    fn test_nonexistent_file() {
        let player = AudioPlayer::new().unwrap();
        
        // Loading a non-existent file should fail
        let result = player.load_file("/nonexistent/file.mp3".to_string());
        assert!(result.is_err());
    }
}

