use colored::*;
use std::path::Path;
use walkdir::WalkDir;

fn main() {
    println!("{}", "==========================================".cyan());
    println!("{}", "   ANTIGRAVITY T490s DEPLOYMENT SCOUT   ".bold().cyan());
    println!("{}", "==========================================".cyan());

    // 1. Check for Installation Image
    println!("\n[*] Scanning for Windows Installation Media...");
    let drives = vec!["D:\\", "E:\\", "F:\\", "G:\\"];
    let mut found_image = false;

    for drive in drives {
        let path = format!("{}sources\\install.wim", drive);
        if Path::new(&path).exists() {
            println!("{} Found install.wim on {}", "[OK]".green(), drive);
            found_image = true;
            break;
        }
    }

    if !found_image {
        println!("{} No installation image detected.", "[WARN]".yellow());
    }

    // 2. Check for Lenovo Drivers
    println!("\n[*] Verifying Intel RST Drivers...");
    let mut driver_found = false;
    for entry in WalkDir::new(".").into_iter().filter_map(|e| e.ok()) {
        if entry.file_name().to_string_lossy().contains("iaStorAC.inf") {
            println!("{} Driver signature match: {:?}", "[OK]".green(), entry.path());
            driver_found = true;
            break;
        }
    }

    if !driver_found {
        println!("{} Drivers not found in current directory.", "[ERROR]".red());
    }

    println!("\n{}", "==========================================".cyan());
    println!("Status: {}", if found_image && driver_found { "READY".green() } else { "INCOMPLETE".red() });
}
