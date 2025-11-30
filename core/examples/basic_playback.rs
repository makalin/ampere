// Basic playback example for Ampere Core
// Run with: cargo run --example basic_playback -- <path-to-audio-file>

use ampere_core::AudioPlayer;
use std::env;

fn main() {
    let args: Vec<String> = env::args().collect();
    
    if args.len() < 2 {
        eprintln!("Usage: cargo run --example basic_playback -- <path-to-audio-file>");
        std::process::exit(1);
    }
    
    let file_path = &args[1];
    
    println!("Creating audio player...");
    let player = match AudioPlayer::new() {
        Ok(p) => p,
        Err(e) => {
            eprintln!("Failed to create audio player: {}", e);
            std::process::exit(1);
        }
    };
    
    println!("Loading file: {}", file_path);
    match player.load_file(file_path.clone()) {
        Ok(_) => println!("File loaded successfully"),
        Err(e) => {
            eprintln!("Failed to load file: {}", e);
            std::process::exit(1);
        }
    }
    
    println!("Playing...");
    match player.play() {
        Ok(_) => println!("Playback started"),
        Err(e) => {
            eprintln!("Failed to play: {}", e);
            std::process::exit(1);
        }
    }
    
    // Wait for playback to finish
    println!("Waiting for playback to finish...");
    loop {
        std::thread::sleep(std::time::Duration::from_millis(100));
        if player.is_finished() {
            println!("Playback finished!");
            break;
        }
    }
}

